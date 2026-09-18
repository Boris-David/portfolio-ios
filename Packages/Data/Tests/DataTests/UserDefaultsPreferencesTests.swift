import Domain
import Foundation
import Testing
@testable import Data

/// Preferences survive relaunches, or they are not preferences.
///
/// ## What is actually being guarded
///
/// The storage format is a deliberate design: `"system"`, `"fr"`, `"en"` — a
/// flat string, not an encoded blob, so a value can be read in Xcode's debug
/// inspector and corrected by hand. The price of that choice is that reading it
/// back is hand-written, and hand-written parsing is exactly where a preference
/// quietly stops persisting.
///
/// The failure mode is silent by nature: nothing crashes, the app simply opens
/// in the wrong language and the person assumes they never set it.
///
/// ## Why every access builds its own `UserDefaults`
///
/// Two reasons, and the second is the one that made this compile.
///
/// A fresh instance on the same suite is the closest thing to a **relaunch**
/// that a test can stage: nothing is carried over in memory, the value has to
/// come back from the store.
///
/// And `UserDefaults` is not `Sendable`. Handing one local instance to an actor
/// and then reading it again in the test sends a value out of its region, which
/// strict concurrency refuses — correctly: the two accesses really would be
/// unordered. Building a new instance per use keeps each one in its own region,
/// which is both what the compiler wants and what the test means.
struct UserDefaultsPreferencesTests {
  /// A suite of its own per test: `UserDefaults.standard` is shared process
  /// state, and two tests writing the same key would pass or fail depending on
  /// the order they happened to run in.
  private func makeSuite() -> String {
    "amissan.tests.\(UUID().uuidString)"
  }

  private func preferences(in suite: String) -> UserDefaultsPreferences {
    UserDefaultsPreferences(defaults: UserDefaults(suiteName: suite)!)
  }

  private func storedValue(forKey key: String, in suite: String) -> String? {
    UserDefaults(suiteName: suite)!.string(forKey: key)
  }

  @Test("a first launch has decided nothing")
  func defaultsOnFirstLaunch() async {
    let suite = makeSuite()
    #expect(await preferences(in: suite).appearance() == .system)
    #expect(await preferences(in: suite).language() == .system)
    #expect(await preferences(in: suite).isBackstageEnabled() == false)
  }

  @Test("the appearance survives a relaunch", arguments: AppearancePreference.allCases)
  func appearanceRoundTrip(_ value: AppearancePreference) async {
    let suite = makeSuite()
    await preferences(in: suite).setAppearance(value)
    #expect(await preferences(in: suite).appearance() == value)
  }

  @Test("the language survives a relaunch", arguments: LanguagePreference.allCases)
  func languageRoundTrip(_ value: LanguagePreference) async {
    let suite = makeSuite()
    await preferences(in: suite).setLanguage(value)
    #expect(await preferences(in: suite).language() == value)
  }

  @Test("the language is stored as a readable string, not a blob")
  func languageIsStoredFlat() async {
    let suite = makeSuite()

    await preferences(in: suite).setLanguage(.fixed(.english))
    #expect(storedValue(forKey: "preference.language", in: suite) == "en")

    await preferences(in: suite).setLanguage(.system)
    #expect(storedValue(forKey: "preference.language", in: suite) == "system")
  }

  /// A value nobody wrote — a hand edit gone wrong, a format from a future
  /// version. Falling back beats refusing to launch over a preference.
  @Test("an unreadable stored language falls back to the system")
  func unknownLanguageFallsBack() async {
    let suite = makeSuite()
    UserDefaults(suiteName: suite)!.set("klingon", forKey: "preference.language")
    #expect(await preferences(in: suite).language() == .system)
  }

  /// Backstage mode survives a relaunch on purpose: somebody who turned it on is
  /// exploring, and taking it away at every launch would be hostile.
  @Test("backstage mode survives a relaunch")
  func backstageRoundTrip() async {
    let suite = makeSuite()
    await preferences(in: suite).setBackstageEnabled(true)
    #expect(await preferences(in: suite).isBackstageEnabled())
  }
}
