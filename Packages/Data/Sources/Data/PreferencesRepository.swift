import Core
import Domain

/// The preferences, on top of `Core`'s key-value store.
///
/// ## Why this file lives in `Data` and not in `Core`
///
/// It implements a **domain port** (`PreferencesStoring`), so it knows the
/// domain. `Core` does not know the domain, and must not: it is where the
/// mechanics live, and a mechanic that has heard of a portfolio is no longer
/// reusable anywhere.
///
/// So the split runs along that line. `Core` owns *how* a scalar survives a
/// relaunch — `KeyValueStore`, and the single `UserDefaults` implementation
/// behind it. This file owns *which* scalars, *under which keys*, and *what they
/// mean*: an appearance, a language, a backstage toggle.
///
/// `Data` is precisely the layer where the domain and the plumbing meet.
///
/// ## Why a key-value store and not the file store next door
///
/// `LocalStore` keeps the **cache** — bulky content the system is allowed to
/// purge. Preferences must not be: somebody who set the app to English does not
/// want to find it in French because the disk was full. Same mechanism, opposite
/// contract.
public actor PreferencesRepository: PreferencesStoring {
  private enum Key {
    static let appearance = "preference.appearance"
    static let language = "preference.language"
    static let backstage = "preference.backstage"
  }

  private let store: any KeyValueStore

  public init(store: any KeyValueStore = UserDefaultsKeyValueStore()) {
    self.store = store
  }

  public func appearance() async -> AppearancePreference {
    store.string(forKey: Key.appearance)
      .flatMap(AppearancePreference.init(rawValue:)) ?? .system
  }

  public func setAppearance(_ value: AppearancePreference) async {
    store.set(value.rawValue, forKey: Key.appearance)
  }

  /// The language is written as `"system"`, `"fr"` or `"en"`.
  ///
  /// A flat string rather than something `Codable`: a preference value can be
  /// read in Xcode's debug inspector and corrected by hand. An encoded JSON blob
  /// cannot be read, and the day it stops decoding, the preference vanishes
  /// without a sound.
  public func language() async -> LanguagePreference {
    switch store.string(forKey: Key.language) {
    case "system", nil: .system
    case let raw?: Language(rawValue: raw).map(LanguagePreference.fixed) ?? .system
    }
  }

  public func setLanguage(_ value: LanguagePreference) async {
    switch value {
    case .system: store.set("system", forKey: Key.language)
    case .fixed(let language): store.set(language.rawValue, forKey: Key.language)
    }
  }

  public func isBackstageEnabled() async -> Bool {
    store.bool(forKey: Key.backstage)
  }

  public func setBackstageEnabled(_ value: Bool) async {
    store.set(value, forKey: Key.backstage)
  }
}
