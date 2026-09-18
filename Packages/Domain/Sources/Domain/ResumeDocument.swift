import Foundation

/// A downloaded résumé.
///
/// It carries a **file URL** and not its bytes. Two reasons, and the second is
/// the real one:
///
///   - `PDFView` and the share sheet read a URL without loading the whole
///     document into memory;
///   - a file has a **name**, and that name is what the recipient of a share
///     sees. Anonymous `Data` would travel under a name the system invented.
public struct ResumeDocument: Sendable, Hashable {
  public let fileURL: URL
  /// The name read from the response's `Content-Disposition` header, never
  /// inferred from the URL: it is the source that decides what its document is
  /// called.
  public let fileName: String
  /// The response's `ETag` — what makes coming back free.
  public let entityTag: String?
  public let origin: ContentOrigin

  public init(fileURL: URL, fileName: String, entityTag: String?, origin: ContentOrigin) {
    self.fileURL = fileURL
    self.fileName = fileName
    self.entityTag = entityTag
    self.origin = origin
  }
}
