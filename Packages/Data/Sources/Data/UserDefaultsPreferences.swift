import Domain
import Foundation

/// The preferences, in `UserDefaults`.
///
/// ## Why this file lives in `Data` and not in `Persistence`
///
/// It implements a **domain port** (`PreferencesStoring`), so it knows the
/// domain. `Persistence` does not know the domain, and must not: it is a layer
/// that writes bytes and ignores what they are for.
///
/// `Data` is precisely the layer where the domain and the plumbing meet. Putting
/// this adapter anywhere else would have made `Persistence` depend on `Domain`
/// for three scalar values — and `ArchitectureTests` would have refused it,
/// which is exactly its job.
///
/// ## Why `UserDefaults` and not the file store next door
///
/// Three scalar values, read at launch and written on every toggle.
/// `UserDefaults` is made for exactly that: synchronised by the system, backed
/// up with the device, and with no file to manage.
///
/// `FileStore` is for the **cache** — bulky content the system is allowed to
/// purge. Preferences must not be: somebody who set the app to English does not
/// want to find it in French because the disk was full.
///
/// It is the same distinction that excluded the cache from iCloud backups, taken
/// the other way round.
public actor UserDefaultsPreferences: PreferencesStoring {
  private enum Key {
    static let appearance = "preference.appearance"
    static let language = "preference.language"
    static let backstage = "preference.backstage"
  }

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func appearance() async -> AppearancePreference {
    defaults.string(forKey: Key.appearance)
      .flatMap(AppearancePreference.init(rawValue:)) ?? .system
  }

  public func setAppearance(_ value: AppearancePreference) async {
    defaults.set(value.rawValue, forKey: Key.appearance)
  }

  /// The language is written as `"system"`, `"fr"` or `"en"`.
  ///
  /// A flat string rather than something `Codable`: a preference value can be
  /// read in Xcode's debug inspector and corrected by hand. An encoded JSON blob
  /// cannot be read, and the day it stops decoding, the preference vanishes
  /// without a sound.
  public func language() async -> LanguagePreference {
    switch defaults.string(forKey: Key.language) {
    case "system", nil: .system
    case let raw?: Language(rawValue: raw).map(LanguagePreference.fixed) ?? .system
    }
  }

  public func setLanguage(_ value: LanguagePreference) async {
    switch value {
    case .system: defaults.set("system", forKey: Key.language)
    case .fixed(let language): defaults.set(language.rawValue, forKey: Key.language)
    }
  }

  public func isBackstageEnabled() async -> Bool {
    defaults.bool(forKey: Key.backstage)
  }

  public func setBackstageEnabled(_ value: Bool) async {
    defaults.set(value, forKey: Key.backstage)
  }
}
