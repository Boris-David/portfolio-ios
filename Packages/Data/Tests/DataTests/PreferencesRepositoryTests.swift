import Core
import Domain
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
/// ## What `Core` changed here
///
/// This suite used to build a `UserDefaults` suite per test, with a UUID in its
/// name, and hand the instance to an actor — which strict concurrency refused,
/// correctly, because `UserDefaults` is not `Sendable`. The workaround was to
/// rebuild an instance on every access.
///
/// Since the mechanism moved behind `KeyValueStoring`, a relaunch is one line:
/// build a second repository on the same store. No suites, no UUIDs, no
/// concurrency workaround — and the test now says what it means instead of
/// saying what `UserDefaults` needed.
struct PreferencesRepositoryTests {
  @Test("a first launch has decided nothing")
  func defaultsOnFirstLaunch() async {
    let preferences = PreferencesRepository(store: InMemoryKeyValueStore())
    #expect(await preferences.appearance() == .system)
    #expect(await preferences.language() == .system)
    #expect(await preferences.showsDecisions() == false)
  }

  @Test("the appearance survives a relaunch", arguments: AppearancePreference.allCases)
  func appearanceRoundTrip(_ value: AppearancePreference) async {
    let store = InMemoryKeyValueStore()
    await PreferencesRepository(store: store).setAppearance(value)
    // A second repository on the same store: that is what a relaunch is.
    #expect(await PreferencesRepository(store: store).appearance() == value)
  }

  @Test("the language survives a relaunch", arguments: LanguagePreference.allCases)
  func languageRoundTrip(_ value: LanguagePreference) async {
    let store = InMemoryKeyValueStore()
    await PreferencesRepository(store: store).setLanguage(value)
    #expect(await PreferencesRepository(store: store).language() == value)
  }

  /// The flat format is the point, so it is asserted rather than assumed.
  @Test("the language is stored as a readable string, not a blob")
  func languageIsStoredFlat() async {
    let store = InMemoryKeyValueStore()
    let preferences = PreferencesRepository(store: store)

    await preferences.setLanguage(.fixed(.english))
    #expect(store.string(forKey: "preference.language") == "en")

    await preferences.setLanguage(.system)
    #expect(store.string(forKey: "preference.language") == "system")
  }

  /// A value nobody wrote — a hand edit gone wrong, a format from a future
  /// version. Falling back beats refusing to launch over a preference.
  @Test("an unreadable stored language falls back to the system")
  func unknownLanguageFallsBack() async {
    let store = InMemoryKeyValueStore(["preference.language": "klingon"])
    #expect(await PreferencesRepository(store: store).language() == .system)
  }

  /// Decisions mode survives a relaunch on purpose: somebody who turned it on is
  /// exploring, and taking it away at every launch would be hostile.
  @Test("decision mode survives a relaunch")
  func decisionsRoundTrip() async {
    let store = InMemoryKeyValueStore()
    await PreferencesRepository(store: store).setShowsDecisions(true)
    #expect(await PreferencesRepository(store: store).showsDecisions())
  }
}
