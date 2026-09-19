/// What an icon **means**, never which glyph draws it.
///
/// ## Why this enum exists at all
///
/// The acid test for a presentation layer is: could this be rendered by
/// something other than SwiftUI without changing a line? A `PhaseFailure`
/// carrying `"wifi.slash"` fails that test — it is an instruction to one
/// specific renderer, on one specific platform, and it makes the presenter a
/// SwiftUI helper rather than a layer.
///
/// So the presenter says `.offline`, and `ViewKit` decides that `.offline` is
/// drawn with `wifi.slash`. Three things follow:
///
/// - the presentation layer is testable with no renderer at all — asserting on
///   `.offline` is exact, where asserting on a glyph string tests spelling;
/// - the icon set changes in one file. Apple renames a symbol, or the design
///   moves to a custom set: nothing above `ViewKit` notices;
/// - a misspelled SF Symbol name renders **nothing**, silently. An enum case
///   cannot be misspelled.
///
/// The cost is one `switch` in `ViewKit`. That is the whole cost.
public enum Icon: Sendable, Hashable, CaseIterable {
  // Failure states
  case offline
  case empty
  case malformed

  // Sections
  case profile
  case work
  case journey
  /// The application he took end to end.
  case product

  // Outcomes
  case succeeded
  case failed
  case informed

  /// Where he will work from — the reader's first filter.
  case remote

  // Actions and settings
  case settings
  case language
  case appearance
  case resume
  case contact
  case share
  case close
  case annotations
  case reset
  case link
}
