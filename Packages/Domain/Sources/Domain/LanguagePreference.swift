/// The chosen language.
///
/// - Note: deliberately **not** `Codable`. Storage writes a flat string
///   (`"system"`, `"fr"`, `"en"`) that can be read in Xcode's debug inspector and
///   corrected by hand. An encoded blob cannot be read — and the day it stops
///   decoding, the preference vanishes without a sound.
public enum LanguagePreference: Sendable, Hashable {
  case system
  case fixed(Language)

  public static let allCases: [LanguagePreference] = [.system] + Language.allCases.map(Self.fixed)
}

public extension LanguagePreference {
  /// The language actually served, once the preference is resolved.
  ///
  /// ⚠️ The fallback is **English**, not French.
  ///
  /// That is counter-intuitive for a portfolio written in French by a French
  /// speaker, and it is the right call: someone whose phone is in German,
  /// Spanish or Portuguese reads English. Falling back to French would serve
  /// only the author.
  ///
  /// French remains the **source's default language** — which is not the same
  /// thing as the default language for an unknown reader.
  func resolved(systemLanguages: [String]) -> Language {
    switch self {
    case .fixed(let language):
      return language
    case .system:
      for identifier in systemLanguages {
        let code = identifier.split(separator: "-").first.map(String.init) ?? identifier
        if let language = Language(rawValue: code.lowercased()) { return language }
      }
      return .english
    }
  }
}
