import Domain
import Testing
@testable import Presentation

/// What the reader chose, and what the rest of the app is told about it.
///
/// ## The two things under guard, and only one of them is obvious
///
/// The obvious one: a preference that does not reach storage is not a
/// preference.
///
/// The other one is the **announcement**. Content is fetched per language, so a
/// language change has to reach the content layer — and an announcement sent
/// when nothing visible changed costs a round trip and a screen that blanks and
/// comes back identical. The rule is therefore not "the preference changed", it
/// is "the language actually **served** changed". The gap between those two
/// sentences is the whole reason this store exists rather than three
/// `@AppStorage` properties, and it is what these tests pin down.
@MainActor
struct SettingsStoreTests {
  /// A French-speaking device unless a test says otherwise: that is the setting
  /// in which "changed the preference" and "changed what is on screen" come
  /// apart.
  private func makeStore(
    preferences: PreferencesSpy = PreferencesSpy(),
    events: EventPublisherSpy = EventPublisherSpy(),
    device: [String] = ["fr-FR"]
  ) -> SettingsStore {
    SettingsStore(preferences: preferences, events: events, systemLanguages: { device })
  }

  // ── Reading back what was kept ─────────────────────────────────────────

  @Test("load serves what storage was holding")
  func loadReadsStorage() async {
    let preferences = PreferencesSpy(
      appearance: .dark,
      language: .fixed(.english),
      showsDecisions: true
    )
    let store = makeStore(preferences: preferences)

    await store.load()

    #expect(store.appearance == .dark)
    #expect(store.language == .fixed(.english))
    #expect(store.showsDecisions)
  }

  // ── Resolving "system" ─────────────────────────────────────────────────

  @Test("a French device asking for the system language is served French")
  func systemFollowsAFrenchDevice() {
    #expect(makeStore(device: ["fr-FR"]).resolvedLanguage == .french)
  }

  /// ⚠️ The fallback is **English**, and this is the test that says so.
  ///
  /// It looks wrong at first glance — a portfolio written in French by a French
  /// speaker, falling back to English — which is exactly why it needs a test
  /// rather than a comment. Someone whose phone is in German, Spanish or
  /// Portuguese reads English; falling back to French would serve only the
  /// author. Anyone "fixing" this to `.french` breaks this test, reads the
  /// sentence, and stops.
  @Test(
    "a device in neither language is served English, not French",
    arguments: [["de-DE"], ["es-ES"], ["pt-BR", "de-DE"], []]
  )
  func systemFallsBackToEnglish(_ device: [String]) {
    #expect(makeStore(device: device).resolvedLanguage == .english)
  }

  /// A chosen language is a decision, not a hint: the device no longer has a
  /// say in it.
  @Test("a fixed language ignores the device entirely")
  func fixedLanguageIgnoresTheDevice() async {
    let store = makeStore(device: ["de-DE"])
    await store.setLanguage(.fixed(.french))
    #expect(store.resolvedLanguage == .french)
  }

  // ── Announcing, and not announcing ─────────────────────────────────────

  @Test("changing the language actually served announces it")
  func announcesWhatTheReaderWillSee() async {
    let events = EventPublisherSpy()
    let store = makeStore(events: events, device: ["fr-FR"])

    await store.setLanguage(.fixed(.english))

    #expect(await events.published == [.languageChanged(.english)])
  }

  /// ⚠️ **The test this suite is written for.**
  ///
  /// On a French device, `.system` already serves French. Moving to
  /// `.fixed(.french)` changes the stored preference and changes nothing the
  /// reader can see — so announcing it would re-fetch a document byte for byte
  /// identical and blank the screen on the way. A guard that only compares
  /// preferences instead of served languages passes every other test in this
  /// file and fails this one.
  @Test("a preference change that serves the same language announces nothing")
  func staysSilentWhenNothingVisibleChanges() async {
    let preferences = PreferencesSpy()
    let events = EventPublisherSpy()
    let store = makeStore(preferences: preferences, events: events, device: ["fr-FR"])

    await store.setLanguage(.fixed(.french))

    // The preference is still recorded — silence is about the announcement, not
    // about dropping the choice.
    #expect(store.language == .fixed(.french))
    #expect(await preferences.language() == .fixed(.french))
    #expect(await events.published.isEmpty)
  }

  /// The mirror image, to prove the rule is about the served language and not
  /// about `.system` being a special case: on a German device, `.system` serves
  /// English, so choosing English explicitly is equally invisible.
  @Test("choosing the language the device was already serving announces nothing")
  func staysSilentOnAForeignDevice() async {
    let events = EventPublisherSpy()
    let store = makeStore(events: events, device: ["de-DE"])

    await store.setLanguage(.fixed(.english))

    #expect(store.resolvedLanguage == .english)
    #expect(await events.published.isEmpty)
  }

  @Test("setting the language it already holds writes nothing")
  func repeatedLanguageIsANoOp() async {
    let preferences = PreferencesSpy()
    let store = makeStore(preferences: preferences)

    await store.setLanguage(.system)

    #expect(await preferences.writeCount == 0)
  }

  // ── Appearance and decision ───────────────────────────────────────────

  @Test("the appearance is kept", arguments: [AppearancePreference.light, .dark])
  func appearanceIsPersisted(_ value: AppearancePreference) async {
    let preferences = PreferencesSpy()
    let store = makeStore(preferences: preferences)

    await store.setAppearance(value)

    #expect(store.appearance == value)
    #expect(await preferences.appearance() == value)
  }

  /// Nothing breaks when a redundant write goes through — which is why it would
  /// never be noticed. It is still a write to disk and an observation cycle for
  /// every screen, fired by a tap that changed nothing.
  @Test("setting the appearance it already holds writes nothing")
  func repeatedAppearanceIsANoOp() async {
    let preferences = PreferencesSpy()
    let store = makeStore(preferences: preferences)

    await store.setAppearance(.system)

    #expect(await preferences.writeCount == 0)
  }

  @Test("decision mode is kept, and turning it on twice writes once")
  func decisionsArePersistedOnce() async {
    let preferences = PreferencesSpy()
    let store = makeStore(preferences: preferences)

    await store.setShowsDecisions(true)
    await store.setShowsDecisions(true)

    #expect(store.showsDecisions)
    #expect(await preferences.showsDecisions())
    #expect(await preferences.writeCount == 1)
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Reset has to reach storage too. A reset that only clears the store leaves
  /// the old values on disk, and the next launch undoes it — the kind of defect
  /// nobody reproduces, because nobody relaunches the app right after resetting.
  @Test("reset puts all three preferences back, on screen and on disk")
  func resetRestoresEverything() async {
    let preferences = PreferencesSpy(
      appearance: .dark,
      language: .fixed(.english),
      showsDecisions: true
    )
    let events = EventPublisherSpy()
    let store = makeStore(preferences: preferences, events: events, device: ["fr-FR"])
    await store.load()

    await store.reset()

    #expect(store.appearance == .system)
    #expect(store.language == .system)
    #expect(!store.showsDecisions)
    #expect(await preferences.appearance() == .system)
    #expect(await preferences.language() == .system)
    #expect(await preferences.showsDecisions() == false)
    // English was on screen, French is now: visible, so announced.
    #expect(await events.published == [.languageChanged(.french)])
  }
}

/// Storage that answers what it was given, and **counts** what it was asked to
/// write.
///
/// The count is what makes "this is a no-op" an assertion rather than a claim:
/// a redundant write is invisible in the resulting state and visible only here.
actor PreferencesSpy: PreferencesStoring {
  private(set) var writeCount = 0
  private var appearanceValue: AppearancePreference
  private var languageValue: LanguagePreference
  private var decisionsValue: Bool

  init(
    appearance: AppearancePreference = .system,
    language: LanguagePreference = .system,
    showsDecisions: Bool = false
  ) {
    appearanceValue = appearance
    languageValue = language
    decisionsValue = showsDecisions
  }

  func appearance() async -> AppearancePreference { appearanceValue }
  func setAppearance(_ value: AppearancePreference) async {
    appearanceValue = value
    writeCount += 1
  }

  func language() async -> LanguagePreference { languageValue }
  func setLanguage(_ value: LanguagePreference) async {
    languageValue = value
    writeCount += 1
  }

  func showsDecisions() async -> Bool { decisionsValue }
  func setShowsDecisions(_ value: Bool) async {
    decisionsValue = value
    writeCount += 1
  }
}

/// A bus that keeps what was published instead of carrying it anywhere.
///
/// These tests are about what the store decides to say, not about delivery —
/// the bus itself is tested in `Core`. Hence the stream that ends immediately:
/// nothing here subscribes, and a stream nobody reads should not hold a
/// continuation open for the rest of the run.
actor EventPublisherSpy: EventPublishing {
  private(set) var published: [AppEvent] = []

  func publish(_ event: AppEvent) async { published.append(event) }

  var events: AsyncStream<AppEvent> {
    AsyncStream { $0.finish() }
  }
}
