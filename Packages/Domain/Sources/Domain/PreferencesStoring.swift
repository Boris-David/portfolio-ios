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

  /// Does decision mode survive a relaunch? Yes: someone who turned it on is
  /// exploring, and taking it away at every launch would be hostile.
  func showsDecisions() async -> Bool
  func setShowsDecisions(_ value: Bool) async
}
