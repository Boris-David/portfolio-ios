import Domain

/// Preferences held in memory — for tests and previews.
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
