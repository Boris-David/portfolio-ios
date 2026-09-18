import Domain
import Foundation

/// Les préférences, dans `UserDefaults`.
///
/// ## Pourquoi ce fichier vit dans `Data` et non dans `Persistence`
///
/// Il implémente un **port du domaine** (`PreferencesStoring`), donc il connaît
/// le domaine. Or `Persistence` ne le connaît pas, et ne doit pas le connaître :
/// c'est une couche qui écrit des octets et ignore à quoi ils servent.
///
/// `Data` est précisément la couche où le domaine et la technique se
/// rencontrent. Mettre cet adaptateur ailleurs aurait fait dépendre `Persistence`
/// de `Domain` pour trois valeurs scalaires — et `ArchitectureTests` l'aurait
/// refusé, ce qui est exactement son travail.
///
/// ## Pourquoi `UserDefaults` et pas le stockage de fichiers d'à côté
///
/// Trois valeurs scalaires, lues au lancement et écrites à chaque bascule.
/// `UserDefaults` est fait exactement pour ça : il est synchronisé par le
/// système, sauvegardé avec l'appareil, et il n'a pas de fichier à gérer.
///
/// `FileStore` sert au **cache** — un contenu volumineux que le système a le
/// droit de purger. Les préférences ne doivent surtout pas l'être : quelqu'un
/// qui a mis l'application en anglais ne veut pas la retrouver en français
/// parce que le disque était plein.
///
/// C'est la même distinction que celle qui a fait exclure le cache des
/// sauvegardes iCloud, prise dans l'autre sens.
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

  /// La langue est écrite comme `"system"`, `"fr"` ou `"en"`.
  ///
  /// Une chaîne plate plutôt qu'un `Codable` : une valeur de préférence se relit
  /// dans le panneau de débogage d'Xcode et se corrige à la main. Un blob JSON
  /// encodé ne se relit pas, et le jour où il ne se décode plus, la préférence
  /// disparaît sans bruit.
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

/// Des préférences en mémoire — pour les tests et les aperçus.
public actor InMemoryPreferences: PreferencesStoring {
  private var appearanceValue: AppearancePreference
  private var languageValue: LanguagePreference
  private var backstageValue: Bool

  public init(
    appearance: AppearancePreference = .system,
    language: LanguagePreference = .system,
    backstage: Bool = false
  ) {
    self.appearanceValue = appearance
    self.languageValue = language
    self.backstageValue = backstage
  }

  public func appearance() async -> AppearancePreference { appearanceValue }
  public func setAppearance(_ value: AppearancePreference) async { appearanceValue = value }
  public func language() async -> LanguagePreference { languageValue }
  public func setLanguage(_ value: LanguagePreference) async { languageValue = value }
  public func isBackstageEnabled() async -> Bool { backstageValue }
  public func setBackstageEnabled(_ value: Bool) async { backstageValue = value }
}
