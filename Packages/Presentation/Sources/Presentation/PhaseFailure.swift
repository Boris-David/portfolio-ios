/// A failure, **already translated for the screen**.
///
/// A view never receives an `Error`. It receives a title, a sentence and an
/// icon, because deciding how a failure is worded is presentation work — and
/// because a view that has to `switch` over domain error cases is a view that
/// knows the domain.
///
/// The message says **what happened and what to do**. No apology, no "an error
/// occurred", which teaches nobody anything.
public struct PhaseFailure: Sendable, Equatable {
  public let title: String
  public let message: String
  /// A **meaning**, not a glyph name. See `Icon`.
  public let icon: Icon
  /// False when retrying would change nothing — malformed content, for example.
  /// Offering "Try again" in that case is a lie.
  public let isRetryable: Bool

  public init(title: String, message: String, icon: Icon, isRetryable: Bool) {
    self.title = title
    self.message = message
    self.icon = icon
    self.isRetryable = isRetryable
  }
}
