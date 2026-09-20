/// The résumé in PDF, produced by the API and served as-is (ADR 0004).
public protocol ResumeReading: Sendable {
  /// The document, written to disk and ready to be opened or shared.
  func resume(in language: Language) async throws -> ResumeDocument
}
