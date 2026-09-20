import Core
import Domain
import Foundation
import Networking

/// The résumé in PDF: downloaded once, revalidated afterwards, never rebuilt.
///
/// ## The full chain, from the API to the screen
///
/// 1. **the request** leaves carrying the `ETag` of the version already held,
///    if there is one — `If-None-Match`;
/// 2. **the server answers `304`** when nothing has changed: not one byte of
///    body crosses the network, and the file already on disk is returned;
/// 3. **otherwise it answers `200`**, and `URLSession` writes the body to a
///    temporary file — never into memory, a PDF has no business going there;
/// 4. **the name** is read from `Content-Disposition`, not inferred from the
///    URL: the source decides what its document is called;
/// 5. **the file is moved** under that name into the cache, and that URL is what
///    `PDFView` opens and what the share sheet hands on.
///
/// Step 5 is the one that matters to the person using the app: sharing anonymous
/// `Data` would land at the recipient under a name the system invented. A file
/// has a name, and that is the name read in Mail.
public actor ResumeRepository: ResumeReading {
  private let client: any HTTPClient
  private let store: any LocalStoring
  private let endpoints: APIEndpoints

  /// As with the content: opening the résumé twice at once makes one download.
  private var downloads: [Language: Task<ResumeDocument, any Error>] = [:]

  public init(client: any HTTPClient, store: any LocalStoring, endpoints: APIEndpoints = .production) {
    self.client = client
    self.store = store
    self.endpoints = endpoints
  }

  public func resume(in language: Language) async throws -> ResumeDocument {
    if let running = downloads[language] {
      return try await running.value
    }
    let task = Task<ResumeDocument, any Error> { try await self.fetch(language) }
    downloads[language] = task
    defer { downloads[language] = nil }
    return try await task.value
  }

  // ───────────────────────────────────────────────────────────────────────

  private func fetch(_ language: Language) async throws -> ResumeDocument {
    let known = await metadata(for: language)
    let request = HTTPRequest(url: endpoints.resume(in: language))
      .revalidating(entityTag: known?.entityTag)

    let download: HTTPDownload
    do {
      download = try await client.download(request)
    } catch {
      // No network: if the document is already here, it does the job perfectly.
      if let cached = try await cachedDocument(for: language, metadata: known) { return cached }
      throw ContentUnavailable.unreachable
    }

    if download.isNotModified, let cached = try await cachedDocument(for: language, metadata: known) {
      return cached
    }

    guard download.isSuccess, let temporaryURL = download.temporaryURL else {
      if let cached = try await cachedDocument(for: language, metadata: known) { return cached }
      throw ContentUnavailable.unreachable
    }

    // The name announced by the source, with a **named** fallback rather than
    // an anonymous one: a server that forgot the header must not produce a share
    // titled "file".
    let fileName = ContentDisposition.fileName(in: download.headers)
      ?? "amissan.ag-cv-\(language.rawValue).pdf"

    guard let key = StorageKey(fileName.lowercased()) else {
      throw ContentUnavailable.malformed(
        path: "Content-Disposition.filename",
        reason: .unacceptableFileName(fileName)
      )
    }

    let destination = await store.location(of: key)
    try? FileManager.default.removeItem(at: destination)
    do {
      try FileManager.default.moveItem(at: temporaryURL, to: destination)
    } catch {
      throw ContentUnavailable.unreachable
    }

    let entityTag = download.headers.entityTag
    await save(Metadata(fileName: fileName, entityTag: entityTag), for: language)

    return ResumeDocument(
      fileURL: destination,
      fileName: fileName,
      entityTag: entityTag,
      origin: .network
    )
  }

  private func cachedDocument(
    for language: Language,
    metadata: Metadata?
  ) async throws -> ResumeDocument? {
    guard let metadata, let key = StorageKey(metadata.fileName.lowercased()) else { return nil }
    let url = await store.location(of: key)
    let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
    guard let size = values?.fileSize, size > 0 else { return nil }

    return ResumeDocument(
      fileURL: url,
      fileName: metadata.fileName,
      entityTag: metadata.entityTag,
      origin: .cache(storedAt: values?.contentModificationDate ?? Date())
    )
  }

  // ── The entity tag and the name, kept beside the document ──────────────

  struct Metadata: Codable, Sendable {
    let fileName: String
    let entityTag: String?
  }

  private func metadataKey(for language: Language) -> StorageKey? {
    StorageKey("resume-\(language.rawValue).meta.json")
  }

  private func metadata(for language: Language) async -> Metadata? {
    guard let key = metadataKey(for: language), let stored = await store.read(key) else { return nil }
    return try? JSONDecoder().decode(Metadata.self, from: stored.data)
  }

  private func save(_ metadata: Metadata, for language: Language) async {
    guard let key = metadataKey(for: language),
          let data = try? JSONEncoder().encode(metadata) else { return }
    try? await store.write(data, for: key)
  }
}
