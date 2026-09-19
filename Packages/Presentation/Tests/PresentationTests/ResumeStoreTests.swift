import Domain
import Foundation
import Testing
@testable import Presentation

/// The four states a download can be in, asserted without downloading anything.
///
/// ## What moving this out of the screen bought
///
/// While this was a model declared next to the view, every one of these states
/// was reachable only by launching the app, putting the phone in flight mode at
/// the right moment, and looking. Here they are values, so the interesting ones
/// — a failure worded for the reader, a reload that must not blank the screen —
/// are three lines each.
///
/// The double gates its answer rather than sleeping, which is what makes
/// `loading` observable at all: the phase in flight is not a duration, it is a
/// moment, and a test that waits for it is a test that sometimes misses it.
@MainActor
struct ResumeStoreTests {
  @Test("the first load goes from initial, through loading, to loaded")
  func firstLoadWalksThePhases() async {
    let reading = ResumeReadingSpy(.document(.stub), isGated: true)
    let store = ResumeStore(reading: reading, language: .french)

    // Nothing has been asked for yet: the screen shows nothing, not a skeleton.
    #expect(store.phase == .initial)

    let load = Task { await store.load() }
    await reading.waitUntilCalled()
    #expect(store.phase == .loading)

    await reading.release()
    await load.value
    #expect(store.phase == .loaded(.stub))
  }

  /// A failure carries the **cause**, never a sentence.
  ///
  /// This test used to hand the store a language and assert on two French
  /// sentences. It cannot any more, and that is the improvement: the store has
  /// no language to be given. What it decides — which glyph, and whether "try
  /// again" would be honest — follows from the cause alone, and the wording is
  /// read from the catalogue by whatever draws it.
  @Test("a failure carries its cause, not its wording", arguments: Language.allCases)
  func failureCarriesItsCause(_ language: Language) async {
    let store = ResumeStore(reading: ResumeReadingSpy(.unavailable(.unreachable)), language: language)

    await store.load()

    guard case .failed(let failure) = store.phase else {
      Issue.record("expected a failure, got \(store.phase)")
      return
    }
    #expect(failure.cause == .unreachable)
    #expect(failure.icon == .offline)
    // The source may well answer next time: the button is honest here.
    #expect(failure.isRetryable)
  }

  /// ⚠️ Retrying a malformed document would ask the same source the same
  /// question and receive the same answer. Offering "Try again" would be a lie
  /// dressed as helpfulness, and the reader would tap it until they gave up —
  /// so the failure carries `isRetryable: false`, and the message carries the
  /// field that broke instead of an apology.
  @Test("a malformed document offers no retry, and says where it broke")
  func malformedFailureIsNotRetryable() async {
    let store = ResumeStore(
      reading: ResumeReadingSpy(
        .unavailable(.malformed(path: "resume.fileName", reason: .missingField))
      ),
      language: .english
    )

    await store.load()

    guard case .failed(let failure) = store.phase else {
      Issue.record("expected a failure, got \(store.phase)")
      return
    }
    #expect(!failure.isRetryable)
    #expect(failure.icon == .malformed)
    // The field path travels intact: it is the part of the diagnosis that is
    // worth anything, and a sentence assembled here would have lost it.
    #expect(failure.cause == .malformed(path: "resume.fileName", reason: .missingField))
  }

  /// An error the domain never named — a session that timed out, a disk that
  /// refused the file. It still has to arrive on screen as something readable:
  /// a `catch` that swallowed it would leave the reader on a skeleton forever,
  /// which is the one outcome worse than an error.
  @Test("an error the domain does not name is still worded, never swallowed")
  func unnamedErrorStillReachesTheScreen() async {
    let store = ResumeStore(reading: ResumeReadingSpy(.unexpected(URLError(.timedOut))), language: .french)

    await store.load()

    guard case .failed(let failure) = store.phase else {
      Issue.record("expected a failure, got \(store.phase)")
      return
    }
    // Reported as unreachable rather than swallowed: a `catch` that dropped it
    // would leave the reader on a skeleton forever, which is the one outcome
    // worse than an error.
    #expect(failure.cause == .unreachable)
    #expect(failure.isRetryable)
  }

  /// ⚠️ The reader can switch language while this sheet is open, which asks for
  /// the document again. Dropping back to `loading` would replace a perfectly
  /// readable page with a skeleton in order to display a wait — trading
  /// something for nothing, and flashing the screen on a gesture that was meant
  /// to refine what it shows.
  @Test("loading again keeps what is already on screen")
  func reloadDoesNotFallBackToASkeleton() async {
    let reading = ResumeReadingSpy(.document(.stub), isGated: true)
    let store = ResumeStore(reading: reading, language: .french)

    let first = Task { await store.load() }
    await reading.waitUntilCalled()
    await reading.release()
    await first.value
    #expect(store.phase == .loaded(.stub))

    let second = Task { await store.setLanguage(.english) }
    await reading.waitUntilCalled()
    #expect(store.phase == .loaded(.stub), "a reload replaced the document with a skeleton")

    await reading.release()
    await second.value
    // The second read really did ask for the other language: the store holds the
    // language and `setLanguage` reloads, precisely so it can change while the
    // sheet is open.
    #expect(await reading.languages == [.french, .english])
  }
}

/// A résumé source that answers what it was told to, records what it was asked
/// for, and — when gated — waits to be let go.
///
/// The gate is the point. `loading` lasts exactly as long as the source takes to
/// answer, so a test that tries to catch it by sleeping catches it most of the
/// time, which is the worst possible amount. Holding the call open makes the
/// phase in flight a fact rather than a race.
actor ResumeReadingSpy: ResumeReading {
  enum Outcome: Sendable {
    case document(ResumeDocument)
    /// A failure the domain names, and the presenter can word precisely.
    case unavailable(ContentUnavailable)
    /// Anything else the transport may throw.
    case unexpected(URLError)
  }

  private(set) var languages: [Language] = []

  private let outcome: Outcome
  private let isGated: Bool
  private var gate: CheckedContinuation<Void, Never>?
  private var arrival: CheckedContinuation<Void, Never>?
  private var hasArrived = false

  init(_ outcome: Outcome, isGated: Bool = false) {
    self.outcome = outcome
    self.isGated = isGated
  }

  func resume(in language: Language) async throws -> ResumeDocument {
    languages.append(language)
    hasArrived = true
    arrival?.resume()
    arrival = nil

    if isGated { await withCheckedContinuation { gate = $0 } }

    switch outcome {
    case .document(let document): return document
    case .unavailable(let failure): throw failure
    case .unexpected(let failure): throw failure
    }
  }

  /// Returns once the call has been entered and is waiting at the gate.
  func waitUntilCalled() async {
    guard !hasArrived else { return }
    await withCheckedContinuation { arrival = $0 }
  }

  /// Lets the waiting call answer, and arms the gate again for the next one.
  func release() {
    hasArrived = false
    gate?.resume()
    gate = nil
  }
}

private extension ResumeDocument {
  static let stub = ResumeDocument(
    fileURL: URL(filePath: "/tmp/amissan-cv-fr.pdf"),
    fileName: "amissan-cv-fr.pdf",
    entityTag: "\"v1\"",
    origin: .network
  )
}
