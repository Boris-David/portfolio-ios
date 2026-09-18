import Foundation

/// The chosen appearance.
///
/// `system` is a **value in its own right**, not the absence of a choice: it
/// means "follow my phone", and it must survive a relaunch like the other two.
public enum AppearancePreference: String, Sendable, Hashable, CaseIterable {
  case system
  case light
  case dark
}

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

/// What the app remembers between launches.
///
/// A port rather than direct `UserDefaults` access: tests must be able to
/// describe a first launch, a preference already set, or storage that refuses to
/// write — three situations a hard-coded `UserDefaults.standard` makes
/// impossible to reproduce.
public protocol PreferencesStoring: Sendable {
  func appearance() async -> AppearancePreference
  func setAppearance(_ value: AppearancePreference) async

  func language() async -> LanguagePreference
  func setLanguage(_ value: LanguagePreference) async

  /// Does backstage mode survive a relaunch? Yes: someone who turned it on is
  /// exploring, and taking it away at every launch would be hostile.
  func isBackstageEnabled() async -> Bool
  func setBackstageEnabled(_ value: Bool) async
}
