/// A short message that appears, says one thing, and leaves on its own.
///
/// ## When a toast is the right answer, and when it is a cop-out
///
/// A toast is for a **fact the reader does not have to act on**: "copied",
/// "saved", "showing the offline copy". It leaves by itself precisely because
/// nothing is expected in return.
///
/// It is the wrong answer for anything that needs a decision — that is an
/// alert or a confirmation dialog — and for anything that must not be missed,
/// because a toast the reader looked away from is a toast that never existed.
/// Using one for an error the app cannot recover from is how a failure gets
/// silently dropped while looking like it was reported.
public struct Toast: Sendable, Equatable, Identifiable {
  public enum Kind: Sendable, Equatable {
    /// It worked.
    case succeeded
    /// It did not, and the reader can do something about it later.
    case failed
    /// Neither — a statement of fact.
    case informed
  }

  public let id: Int
  public let message: String
  public let kind: Kind
  /// The icon's **meaning**; `ViewKit` turns it into a glyph.
  public let icon: Icon

  public init(id: Int, message: String, kind: Kind, icon: Icon) {
    self.id = id
    self.message = message
    self.kind = kind
    self.icon = icon
  }
}
