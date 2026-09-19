/// The languages served.
///
/// How one gets chosen is decided in `LanguagePreference` and nowhere else —
/// there is deliberately **no** `Language.fallback` here. A fallback constant on
/// the type would have ended up used in two places with two different rules,
/// which is exactly what this avoids.
public enum Language: String, Sendable, Hashable, CaseIterable {
  case french = "fr"
  case english = "en"
}
