import Core
import Domain
import Foundation
import Networking

/// The content gateway: the source first, the local copy only when it fails.
///
/// ## The order, and why it is this one
///
/// 1. **the network** — the truth, whenever it answers;
/// 2. **the disk cache** — what the last session brought back;
/// 3. **the bundled seed** — produced at build time from the source, so that a
///    very first launch with no network still shows something.
///
/// An earlier version had this order reversed, and it was wrong. Serving the
/// cache first made the screen appear instantly and then rebuild itself, and for
/// the length of that pause it showed dated content with the confidence of new
/// content. The local copy no longer exists to display *fast*; it exists to
/// display *at all* — dropped connection, timeout, aeroplane mode. And when it
/// is used, the screen **says so**, with the date.
///
/// ## Why an actor rather than a lock
///
/// Four screens appearing together ask for the content together. With no
/// coordination that is four requests, four concurrent cache writes — therefore
/// a half-written file — and two possible versions on screen.
///
/// The fix is not to lock: it is to **remember the refresh already in flight**.
/// Concurrent callers do not start a new one, they await the same one. A single
/// round trip, however many askers.
///
/// A lock would have protected the state provided everybody remembered to take
/// it everywhere — nothing checks that — and a lock held across an `await` is a
/// deadlock waiting for its moment. With an actor, isolation is a **property of
/// the type**: the compiler refuses unserialised access, and forgetting becomes
/// impossible.
public actor PortfolioRepository: PortfolioReading {
  private let client: any HTTPClient
  private let store: any LocalStore
  private let endpoints: APIEndpoints
  private let seed: any SeedProviding
  private let clock: any DateProviding
  private let connectivity: any ConnectivityReporting

  /// The refresh in flight, per language. This is **all** of the coordination.
  private var refreshes: [Language: Task<Loaded, any Error>] = [:]

  public init(
    client: any HTTPClient,
    store: any LocalStore,
    seed: any SeedProviding,
    endpoints: APIEndpoints = .production,
    clock: any DateProviding = SystemClock(),
    // `.unknown` by default, and that is the safe default: not knowing is not a
    // reason to stop trying. Only a monitor that has actually seen the path go
    // down short-circuits anything.
    connectivity: any ConnectivityReporting = StaticConnectivity(.unknown)
  ) {
    self.client = client
    self.store = store
    self.endpoints = endpoints
    self.seed = seed
    self.clock = clock
    self.connectivity = connectivity
  }

  public func portfolio(
    in language: Language,
    policy: FreshnessPolicy
  ) async throws -> PortfolioSnapshot {
    // `cacheFirst`: go to the network only when the local copy is missing or has
    // aged out. This is the "cache on some calls" mechanism, made explicit by
    // the caller rather than imposed on everyone.
    if case .cacheFirst(let maxAge) = policy,
       let local = await localSnapshot(for: language),
       isFresh(local, within: maxAge) {
      return local
    }

    // ── Known offline: do not spend fifteen seconds proving it ───────────
    //
    // "Offline" used to be **inferred from a failure**: fire the request, wait
    // for the timeout, then fall back. The person waited fifteen seconds to be
    // told what the system knew before the request left.
    //
    // This is not a return to cache-first. The rule is unchanged — the source is
    // asked whenever it can be reached. What changes is that a request which
    // *cannot* leave is no longer sent, and the screen says why immediately.
    //
    // `.unknown` does not take this path: not knowing is not a reason to give up.
    if await connectivity.current.isKnownOffline {
      guard let local = await localSnapshot(for: language) else {
        throw ContentUnavailable.nothingAvailable
      }
      return PortfolioSnapshot(
        portfolio: local.portfolio,
        contentVersion: local.contentVersion,
        origin: local.origin,
        refreshFailure: .unreachable
      )
    }

    do {
      let fresh = try await refreshed(language)
      return PortfolioSnapshot(
        portfolio: fresh.portfolio,
        contentVersion: fresh.contentVersion,
        origin: .network
      )
    } catch {
      let failure = contentFailure(from: error)

      // A malformed payload is **not** rescued by the cache: the local content
      // would describe a different version of the world, and we would be hiding
      // a defect in the source instead of reporting it. Only **transport**
      // failures justify falling back.
      guard case .unreachable = failure, let local = await localSnapshot(for: language) else {
        throw unrecoverable(failure)
      }

      return PortfolioSnapshot(
        portfolio: local.portfolio,
        contentVersion: local.contentVersion,
        origin: local.origin,
        refreshFailure: failure
      )
    }
  }

  /// The failure to report when there is nothing at all to fall back on.
  ///
  /// "Unreachable" with an empty device and "unreachable" with a usable cache do
  /// not call for the same sentence, so the first becomes `nothingAvailable`. A
  /// malformed payload keeps its own diagnosis: it names the field.
  private func unrecoverable(_ failure: ContentUnavailable) -> ContentUnavailable {
    if case .malformed = failure { return failure }
    return .nothingAvailable
  }

  private func isFresh(_ snapshot: PortfolioSnapshot, within maxAge: Duration) -> Bool {
    let storedAt: Date
    switch snapshot.origin {
    case .cache(let date): storedAt = date
    // The bundled seed has no useful age: it dates from the build, and it is
    // never "fresh" in the sense a cache policy means.
    case .bundledSeed, .network: return false
    }
    return clock.now.timeIntervalSince(storedAt) < Double(maxAge.components.seconds)
  }

  /// The refresh, **shared** between every simultaneous caller.
  private func refreshed(_ language: Language) async throws -> Loaded {
    if let running = refreshes[language] {
      return try await running.value
    }

    let task = Task<Loaded, any Error> { [client, store, endpoints] in
      let request = HTTPRequest(
        url: endpoints.portfolio(in: language),
        headers: ["Accept": "application/json"]
      )
      let response = try await client.send(request)
      guard response.isSuccess else { throw HTTPError.status(response.status) }

      let loaded = try Self.decode(response.body, expecting: language)
      // The cache is written with the bytes **received**, not with a re-encoding
      // of what was decoded: re-encoding would drop any field not read yet, and
      // a later version of the app would look for it in vain inside a cache it
      // had impoverished itself.
      if let key = Self.cacheKey(for: language) {
        try? await store.write(response.body, for: key)
      }
      return loaded
    }

    refreshes[language] = task
    defer { refreshes[language] = nil }
    return try await task.value
  }

  private func localSnapshot(for language: Language) async -> PortfolioSnapshot? {
    if let key = Self.cacheKey(for: language),
       let stored = await store.read(key),
       let loaded = try? Self.decode(stored.data, expecting: language) {
      return PortfolioSnapshot(
        portfolio: loaded.portfolio,
        contentVersion: loaded.contentVersion,
        origin: .cache(storedAt: stored.storedAt)
      )
    }

    if let seedData = seed.data(for: language),
       let loaded = try? Self.decode(seedData, expecting: language) {
      return PortfolioSnapshot(
        portfolio: loaded.portfolio,
        contentVersion: loaded.contentVersion,
        origin: .bundledSeed(builtAt: seed.builtAt)
      )
    }

    return nil
  }

  // ── Decoding ───────────────────────────────────────────────────────────

  struct Loaded: Sendable {
    let portfolio: Portfolio
    let contentVersion: String
  }

  static func decode(_ data: Foundation.Data, expecting language: Language) throws -> Loaded {
    let envelope: PortfolioEnvelopeDTO
    do {
      envelope = try JSONDecoder().decode(PortfolioEnvelopeDTO.self, from: data)
    } catch let error as DecodingError {
      // `DecodingError` already carries the path of the offending field:
      // translating it yields, for free, the diagnosis we would otherwise have
      // written by hand.
      throw ContentUnavailable.malformed(path: path(of: error), reason: reason(of: error))
    }

    // A response served in a language other than the one requested is an error,
    // not a fallback: showing English to somebody who asked for French is a
    // failure you only notice once, in production.
    guard envelope.meta.locale == language.rawValue else {
      throw ContentUnavailable.malformed(
        path: "meta.locale",
        reason: .wrongLanguage(served: envelope.meta.locale, requested: language.rawValue)
      )
    }

    do {
      return Loaded(
        portfolio: try PortfolioMapper.portfolio(from: envelope.data),
        contentVersion: envelope.meta.contentVersion
      )
    } catch let error as MappingError {
      throw ContentUnavailable.malformed(path: error.path, reason: error.reason)
    }
  }

  static func cacheKey(for language: Language) -> StorageKey? {
    StorageKey("portfolio-\(language.rawValue).json")
  }

  // ── Translating failures ───────────────────────────────────────────────

  private func contentFailure(from error: any Error) -> ContentUnavailable {
    switch error {
    case let unavailable as ContentUnavailable: unavailable
    default: .unreachable
    }
  }

  private static func path(of error: DecodingError) -> String {
    let keys: [any CodingKey] = switch error {
    case .keyNotFound(let key, let context): context.codingPath + [key]
    case .typeMismatch(_, let context), .valueNotFound(_, let context),
         .dataCorrupted(let context): context.codingPath
    @unknown default: []
    }
    return keys.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }
      .joined()
      .trimmingCharacters(in: CharacterSet(charactersIn: "."))
  }

  private static func reason(of error: DecodingError) -> MalformedReason {
    switch error {
    case .keyNotFound: .missingField
    case .typeMismatch(let type, _): .unexpectedType(expected: "\(type)")
    case .valueNotFound(let type, _): .nullValue(expected: "\(type)")
    case .dataCorrupted(let context): .unreadable(detail: context.debugDescription)
    @unknown default: .unreadable(detail: "unreadable payload")
    }
  }
}
