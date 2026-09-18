import Domain

/// A failure, reduced to **what the screen must decide**.
///
/// A view never receives an `Error`. It receives the cause as a value, a meaning
/// for the glyph, and whether retrying could change anything — because deciding
/// *that* is presentation work, while deciding *how it is worded* is not.
///
/// ## Why it no longer carries a title and a message
///
/// It used to. Building them needed the language on screen, so `PortfolioStore`
/// had to hold an `AppChrome` for the sole purpose of writing two sentences —
/// and a store that can write a sentence is a store that cannot be tested
/// without a language.
///
/// Now the cause travels as a value and the view layer turns it into text, at
/// the last possible moment, from the catalogue. The wording says **what
/// happened and what to do**: no apology, no "an error occurred", which teaches
/// nobody anything.
public struct PhaseFailure: Sendable, Equatable {
  /// What went wrong, unreduced — the field path of a malformed response is
  /// carried all the way to the screen, because "invalid content" with no
  /// location helps nobody.
  public let cause: ContentUnavailable

  /// A **meaning**, not a glyph name. See `Icon`.
  public let icon: Icon

  /// False when retrying would change nothing — malformed content, for example.
  /// Offering "Try again" in that case is a lie.
  public let isRetryable: Bool

  public init(cause: ContentUnavailable, icon: Icon, isRetryable: Bool) {
    self.cause = cause
    self.icon = icon
    self.isRetryable = isRetryable
  }
}

public extension PhaseFailure {
  /// The presentation decisions a failure carries, and the only ones.
  ///
  /// Which glyph, and whether "Try again" is honest. Both follow from the cause
  /// alone, and neither needs a language.
  init(_ cause: ContentUnavailable) {
    switch cause {
    case .unreachable:
      self.init(cause: cause, icon: .offline, isRetryable: true)
    case .nothingAvailable:
      self.init(cause: cause, icon: .empty, isRetryable: true)
    case .malformed:
      // Retrying a malformed response returns the same malformed response. The
      // button would be a lie, so there is no button.
      self.init(cause: cause, icon: .malformed, isRetryable: false)
    }
  }
}
