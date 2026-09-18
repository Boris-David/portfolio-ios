import Domain
import Foundation
import Networking
import Persistence

/// Le CV en PDF : téléchargé une fois, revalidé ensuite, jamais reconstruit.
///
/// ## La chaîne complète, de l'API à l'écran
///
/// 1. **la requête** part avec l'`ETag` de la version qu'on a déjà, s'il y en a
///    une — `If-None-Match` ;
/// 2. **le serveur répond `304`** si rien n'a changé : aucun octet de corps ne
///    traverse le réseau, et on rend le fichier déjà sur disque ;
/// 3. **sinon il répond `200`**, et `URLSession` écrit le corps dans un fichier
///    temporaire — jamais en mémoire, un PDF n'a pas à y passer ;
/// 4. **le nom** est lu dans `Content-Disposition`, pas déduit de l'URL : c'est
///    la source qui décide comment son document s'appelle ;
/// 5. **le fichier est déplacé** sous ce nom dans le cache, et c'est cette URL
///    que `PDFView` ouvre et que la feuille de partage transmet.
///
/// L'étape 5 est celle qui compte pour l'utilisateur : partager un `Data`
/// anonyme le ferait arriver chez le destinataire sous un nom inventé par le
/// système. Un fichier a un nom, et c'est celui-là qu'on lit dans Mail.
public actor ResumeRepository: ResumeReading {
  private let client: any HTTPClient
  private let store: any LocalStore
  private let endpoints: Endpoints

  /// Comme pour le contenu : deux ouvertures simultanées du CV ne font qu'un
  /// téléchargement.
  private var downloads: [Language: Task<ResumeDocument, any Error>] = [:]

  public init(client: any HTTPClient, store: any LocalStore, endpoints: Endpoints = .production) {
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
      // Pas de réseau : si on a déjà le document, il fait parfaitement l'affaire.
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

    // Le nom annoncé par la source, avec un repli **nommé** plutôt qu'anonyme :
    // un serveur qui oublierait l'en-tête ne doit pas produire un partage
    // intitulé « file ».
    let fileName = ContentDisposition.fileName(in: download.headers)
      ?? "amissan.ag-cv-\(language.rawValue).pdf"

    guard let key = StorageKey(fileName.lowercased()) else {
      throw ContentUnavailable.malformed(
        path: "Content-Disposition.filename",
        reason: "« \(fileName) » n'est pas un nom de fichier acceptable"
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

  // ── L'empreinte et le nom, conservés à côté du document ─────────────────

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
