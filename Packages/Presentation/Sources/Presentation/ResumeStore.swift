import Domain
import Observation

/// The résumé's state, for the screen that shows it.
///
/// ## Why it moved out of the screen file
///
/// It was a `ResumeModel` declared next to the view — which worked, and meant
/// the four states a download can be in were only reachable by launching the
/// app. Here they are values: a test can assert that a failure with a cached
/// copy shows the copy, without a simulator and without a PDF.
///
/// ## Why the store holds the language, and reloads when it changes
///
/// Because it changes. The reader can switch language while this sheet is open,
/// and a document fetched in the old one would stay on screen. Holding it here
/// and reloading on `setLanguage` keeps that correct **and** keeps the screen
/// out of it: a view that had to supply the language would be a view handling
/// one, and the composition root is the only place allowed to decide.
@Observable
@MainActor
public final class ResumeStore {
  public private(set) var phase: ViewPhase<ResumeDocument> = .initial

  private let reading: any ResumeReading

  /// The language of the document to fetch.
  ///
  /// Held here rather than passed at every call, exactly as `PortfolioStore`
  /// holds its own. A screen that had to supply it would be a screen handling a
  /// language, and the only place allowed to decide one is the composition root.
  /// Readable, because the screen has to say which language the document it
  /// is showing was produced in. It stays settable only from here — the
  /// composition root decides the language, and a view that could set it would
  /// be a view handling localisation.
  public private(set) var language: Language

  public init(reading: any ResumeReading, language: Language) {
    self.reading = reading
    self.language = language
  }

  /// Follows the language actually served, and fetches the document again.
  ///
  /// Called by the composition root when the served language changes — the one
  /// place in the app that decides a language.
  public func setLanguage(_ language: Language) async {
    guard language != self.language else { return }
    self.language = language
    await load()
  }

  public func load() async {
    if !phase.isLoaded { phase = .loading }
    do {
      phase = .loaded(try await reading.resume(in: language))
    } catch let failure as ContentUnavailable {
      phase = .failed(PhaseFailure(failure))
    } catch {
      phase = .failed(PhaseFailure(.unreachable))
    }
  }
}
