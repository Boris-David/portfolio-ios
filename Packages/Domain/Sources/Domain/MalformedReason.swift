/// Why a field could not be read — as a **value**, never as a sentence.
///
/// ## The defect this replaces
///
/// The reason used to be a `String`, built in the data layer, in French:
/// *« date « 2025-13 » illisible »*. It was then shown verbatim on screen — in
/// an English session too. The app's whole premise is that the displayed
/// language is the one the *source* serves, and here a layer three floors below
/// the screen was writing user-facing prose in one language.
///
/// It is the same defect that produced French tabs over English content, one
/// layer down. A layer that cannot see the language must not write sentences.
///
/// So: the data layer says *what* is wrong, `AppChrome` says it in the reader's
/// language, and neither has to know the other's job. The values quoted back —
/// a date, a role, a URL — stay verbatim: they came from the source and belong
/// to no language.
public enum MalformedReason: Sendable, Hashable {
  /// The field is simply not there.
  case missingField
  /// Present, but of another type. `expected` is a type name, not prose.
  case unexpectedType(expected: String)
  /// Present and null, where a value was required.
  case nullValue(expected: String)
  /// The payload could not be parsed at all.
  case unreadable(detail: String)
  /// The source answered in a language other than the one requested.
  case wrongLanguage(served: String, requested: String)
  /// A closed set the source stepped outside of — an unknown application role,
  /// for instance.
  case unknownValue(String)
  /// A date that matches neither `YYYY` nor `YYYY-MM`.
  case unreadableDate(String)
  /// A month outside 01–12.
  case monthOutOfRange(String)
  /// A name the source announced that cannot safely become a file name —
  /// a path, or something with a separator in it.
  case unacceptableFileName(String)
  /// A URL that is not `https`. Refused rather than corrected: a portfolio that
  /// silently opened `http` would teach the wrong thing.
  case insecureURL(String)
}
