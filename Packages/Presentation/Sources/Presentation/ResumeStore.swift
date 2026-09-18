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
/// ## Why the language is a parameter of `load` and not of `init`
///
/// Because it changes. The reader can switch language while this sheet is open,
/// and a language captured at construction would keep serving the old document
/// until the screen was rebuilt — which, being a sheet, it would not be.
@Observable
@MainActor
public final class ResumeStore {
  public private(set) var phase: ViewPhase<ResumeDocument> = .initial

  private let reading: any ResumeReading

  public init(reading: any ResumeReading) {
    self.reading = reading
  }

  public func load(in language: Language) async {
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
