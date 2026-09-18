import Domain
import Foundation
import Observation

/// What the reader chose, and everything that follows from it.
///
/// ## Why this is a store and not three `@AppStorage` properties
///
/// `@AppStorage` would be four lines and would be wrong here, for three reasons
/// that only show up later:
///
/// - it reaches `UserDefaults.standard` from inside a view, which makes the
///   screen untestable at any value other than whatever the simulator happens to
///   hold;
/// - it cannot **resolve** anything. "System" is not a language; it is an
///   instruction to go and look at one, and the fallback when the device speaks
///   neither French nor English is a product decision (English) that has no
///   business living in a property wrapper;
/// - it cannot announce. A language change has to reach the content layer, and
///   `@AppStorage` has no way to say so beyond hoping every view re-renders.
///
/// ## Why it publishes rather than calling
///
/// When the language changes, the content must be re-fetched. This store could
/// call the portfolio store directly — and then the two would know each other
/// forever, for one line. It publishes `languageChanged` instead, and whoever
/// cares subscribes. That is the one shape the event bus is for: a fact, and an
/// unknown number of parts that need it.
@Observable
@MainActor
public final class SettingsStore {
  public private(set) var appearance: AppearancePreference = .system
  public private(set) var language: LanguagePreference = .system
  public private(set) var isBackstageEnabled = false

  /// The language actually served, once "system" has been resolved.
  ///
  /// Recomputed rather than stored: two values that must agree are two values
  /// that eventually will not.
  public var resolvedLanguage: Language {
    language.resolved(systemLanguages: systemLanguages())
  }

  private let preferences: any PreferencesStoring
  private let events: any EventPublishing
  private let systemLanguages: @Sendable () -> [String]

  public init(
    preferences: any PreferencesStoring,
    events: any EventPublishing,
    // Injected so a test can describe a device in German — which is the case
    // that proves the fallback is English and not French.
    systemLanguages: @escaping @Sendable () -> [String] = { Locale.preferredLanguages }
  ) {
    self.preferences = preferences
    self.events = events
    self.systemLanguages = systemLanguages
  }

  /// Reads what was stored. Called once, before the first frame.
  public func load() async {
    appearance = await preferences.appearance()
    language = await preferences.language()
    isBackstageEnabled = await preferences.isBackstageEnabled()
  }

  public func setAppearance(_ value: AppearancePreference) async {
    guard value != appearance else { return }
    appearance = value
    await preferences.setAppearance(value)
  }

  public func setLanguage(_ value: LanguagePreference) async {
    guard value != language else { return }
    let previous = resolvedLanguage
    language = value
    await preferences.setLanguage(value)

    // Only announce when the language actually **served** changed. Moving from
    // `.system` to `.fixed(.french)` on a French device changes the preference
    // and changes nothing the reader can see — announcing it would re-fetch the
    // same content and flash the screen for no reason.
    if resolvedLanguage != previous {
      await events.publish(.languageChanged(resolvedLanguage))
    }
  }

  public func setBackstageEnabled(_ value: Bool) async {
    guard value != isBackstageEnabled else { return }
    isBackstageEnabled = value
    await preferences.setBackstageEnabled(value)
  }

  /// Puts everything back. Announces only if it changed something visible.
  public func reset() async {
    await setAppearance(.system)
    await setLanguage(.system)
    await setBackstageEnabled(false)
  }
}
