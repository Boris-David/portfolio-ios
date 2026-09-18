import Domain
import Foundation
import Observation

/// The content's state, for every screen.
///
/// ## One store, not one per screen
///
/// Four tabs show the same portfolio. Four stores would be four reads, four
/// possible refresh moments, and one tab showing a version while another shows a
/// second one. Nobody would ever see it — which is precisely the problem.
///
/// ## `@MainActor` on the whole class
///
/// It exists only to feed views. Isolating the class rather than marking each
/// property avoids the question on every addition, and the compiler then refuses
/// any read from another context — which is the guarantee we are after, not a
/// `DispatchQueue.main.async` applied out of habit.
///
/// ## Why it lives in `Presentation` and imports no SwiftUI
///
/// `@Observable` comes from the Observation framework, not from SwiftUI. So this
/// class — the one that decides what a screen shows and how a failure is worded
/// — is testable with values alone: no simulator, no renderer, no snapshot.
@Observable
@MainActor
public final class PortfolioStore {
  /// The screen's phase. Four cases, and not one more.
  public private(set) var phase: ViewPhase<PortfolioSnapshot> = .initial

  /// Orthogonal to the phase: a refresh starts from `loaded` as readily as from
  /// `failed`. Making it a fifth case would produce combinations nobody could
  /// name.
  public private(set) var isRefreshing = false

  public private(set) var language: Language

  private let reading: any PortfolioReading
  private let chrome: () -> AppChrome
  private var loadTask: Task<Void, Never>?

  public init(
    reading: any PortfolioReading,
    language: Language,
    chrome: @escaping () -> AppChrome
  ) {
    self.reading = reading
    self.language = language
    self.chrome = chrome
  }

  public var snapshot: PortfolioSnapshot? { phase.value }
  public var portfolio: Portfolio? { snapshot?.portfolio }

  /// The first load, or a reload after a language change.
  ///
  /// The phase goes through `loading` **only when there is nothing to show**. A
  /// reload with content already on screen does not replace it with a skeleton:
  /// that would be losing what we have in order to display a wait.
  public func load(policy: FreshnessPolicy = .networkFirst) {
    loadTask?.cancel()
    if !phase.isLoaded { phase = .loading }
    isRefreshing = phase.isLoaded

    loadTask = Task { [reading, language] in
      defer { isRefreshing = false }
      do {
        let snapshot = try await reading.portfolio(in: language, policy: policy)
        guard !Task.isCancelled else { return }
        phase = .loaded(snapshot)
      } catch let unavailable as ContentUnavailable {
        guard !Task.isCancelled else { return }
        // A failure never overwrites content already on screen: dated content
        // beats an error screen in the place of something readable.
        if !phase.isLoaded { phase = .failed(PhaseFailure(unavailable, chrome: chrome())) }
      } catch {
        guard !Task.isCancelled else { return }
        if !phase.isLoaded { phase = .failed(PhaseFailure(.unreachable, chrome: chrome())) }
      }
    }
  }

  /// A reload the reader asked for — the pull-to-refresh gesture.
  ///
  /// It genuinely waits for the end: without that, the indicator would disappear
  /// before the content arrived, which reads as the gesture having done
  /// nothing.
  public func refresh() async {
    load()
    await loadTask?.value
  }

  /// Changes the displayed language, and reloads straight away.
  public func setLanguage(_ language: Language) {
    guard language != self.language else { return }
    self.language = language
    // The other language's content is not this one: start from an empty phase
    // rather than show French while English is on its way.
    phase = .loading
    load()
  }
}
