import Domain
import Foundation
import Networking
import Persistence
import Testing
@testable import Data

/// The freshness policy, and the coordination around it.
///
/// These tests encode a rule the author stated plainly: **the network first;
/// local content only when the network fails.** The previous version served the
/// cache first and refreshed behind it — fast, and dishonest, because it showed
/// dated content with the confidence of fresh content.
struct PortfolioRepositoryTests {
  private func makeRepository(
    client: CountingClient,
    store: MemoryStore = MemoryStore(),
    seed: any SeedProviding = EmptySeed(),
    now: Date = Date(timeIntervalSince1970: 1_800_000_000)
  ) -> PortfolioRepository {
    PortfolioRepository(client: client, store: store, seed: seed, clock: { now })
  }

  // ── Network first ──────────────────────────────────────────────────────

  @Test("serves the network when it answers")
  func networkWins() async throws {
    let repository = makeRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      seed: FixtureSeed()
    )

    let snapshot = try await repository.portfolio(in: .french, policy: .networkFirst)

    #expect(snapshot.origin == .network)
    #expect(snapshot.refreshFailure == nil)
    #expect(!snapshot.isStale)
  }

  /// The whole point of keeping anything locally: a tunnel, a plane, a dead
  /// cell. Not speed — availability.
  @Test("falls back to the cache when the network is unreachable")
  func fallsBackToCache() async throws {
    let cached = try #require(Fixtures.payload(.french))
    let repository = makeRepository(
      client: CountingClient(response: .failure(.transport(description: "offline"))),
      store: MemoryStore(seeded: ["portfolio-fr.json": cached])
    )

    let snapshot = try await repository.portfolio(in: .french, policy: .networkFirst)

    guard case .cache = snapshot.origin else {
      Issue.record("expected the cache, got \(snapshot.origin)")
      return
    }
    // The failure is carried, not swallowed: "I did not try" and "I tried and
    // could not" do not read the same on screen.
    #expect(snapshot.refreshFailure == .unreachable)
    #expect(snapshot.isStale)
  }

  @Test("falls back to the bundled seed when there is no cache")
  func fallsBackToSeed() async throws {
    let repository = makeRepository(
      client: CountingClient(response: .failure(.transport(description: "offline"))),
      seed: FixtureSeed()
    )

    let snapshot = try await repository.portfolio(in: .french, policy: .networkFirst)

    guard case .bundledSeed = snapshot.origin else {
      Issue.record("expected the bundled seed, got \(snapshot.origin)")
      return
    }
  }

  @Test("throws when nothing at all is available")
  func throwsWithNothing() async {
    let repository = makeRepository(
      client: CountingClient(response: .failure(.transport(description: "offline")))
    )

    await #expect(throws: ContentUnavailable.nothingAvailable) {
      _ = try await repository.portfolio(in: .french, policy: .networkFirst)
    }
  }

  /// ⚠️ A malformed payload is **not** rescued by the cache.
  ///
  /// Local content would describe a different version of the world, and we would
  /// be hiding a defect in the source instead of reporting it. Only transport
  /// failures justify falling back.
  @Test("does not hide a malformed payload behind the cache")
  func malformedIsNotMasked() async throws {
    let cached = try #require(Fixtures.payload(.french))
    let repository = makeRepository(
      client: CountingClient(response: .success(Fixtures.responseMissing(["data", "profile"]))),
      store: MemoryStore(seeded: ["portfolio-fr.json": cached])
    )

    do {
      _ = try await repository.portfolio(in: .french, policy: .networkFirst)
      Issue.record("a malformed payload must surface, not fall back")
    } catch let failure as ContentUnavailable {
      guard case .malformed(let path, _) = failure else {
        Issue.record("expected .malformed, got \(failure)")
        return
      }
      #expect(path.contains("profile"))
    }
  }

  // ── Cache first, by exception ──────────────────────────────────────────

  @Test("cacheFirst skips the network while the cache is young enough")
  func cacheFirstSkipsNetwork() async throws {
    let cached = try #require(Fixtures.payload(.french))
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    // MemoryStore stamps its seeded values at a fixed instant; the clock is set
    // one hour later, so a one-day budget still holds.
    let repository = makeRepository(
      client: client,
      store: MemoryStore(seeded: ["portfolio-fr.json": cached]),
      now: Date(timeIntervalSince1970: 1_700_003_600)
    )

    let snapshot = try await repository.portfolio(
      in: .french,
      policy: .cacheFirst(maxAge: .seconds(86_400))
    )

    guard case .cache = snapshot.origin else {
      Issue.record("expected the cache, got \(snapshot.origin)")
      return
    }
    #expect(await client.sendCount == 0, "the network must not be touched")
  }

  @Test("cacheFirst goes to the network once the cache is too old")
  func cacheFirstExpires() async throws {
    let cached = try #require(Fixtures.payload(.french))
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = makeRepository(
      client: client,
      store: MemoryStore(seeded: ["portfolio-fr.json": cached]),
      now: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let snapshot = try await repository.portfolio(
      in: .french,
      policy: .cacheFirst(maxAge: .seconds(60))
    )

    #expect(snapshot.origin == .network)
    #expect(await client.sendCount == 1)
  }

  /// The bundled seed has no useful age: it dates from the build, and it is
  /// never "fresh" in the sense of a cache policy.
  @Test("cacheFirst never treats the bundled seed as fresh")
  func seedIsNeverFresh() async throws {
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = makeRepository(client: client, seed: FixtureSeed())

    let snapshot = try await repository.portfolio(
      in: .french,
      policy: .cacheFirst(maxAge: .seconds(86_400))
    )

    #expect(snapshot.origin == .network)
    #expect(await client.sendCount == 1)
  }

  // ── Coalescing ─────────────────────────────────────────────────────────

  /// **The most important test in this module.**
  ///
  /// Four screens ask for content as they appear. Without coordination that is
  /// four requests, four concurrent cache writes — hence a half-written file —
  /// and two possible versions on screen. Nobody would ever see it, which is
  /// exactly what makes the defect expensive.
  @Test("four simultaneous reads make one request")
  func concurrentReadsShareOneRequest() async throws {
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = makeRepository(client: client)

    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<4 {
        group.addTask {
          _ = try? await repository.portfolio(in: .french, policy: .networkFirst)
        }
      }
    }

    #expect(await client.sendCount == 1)
  }

  @Test("two languages asked at once make two requests")
  func languagesAreNotShared() async throws {
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = makeRepository(client: client)

    async let fr = try? await repository.portfolio(in: .french, policy: .networkFirst)
    async let en = try? await repository.portfolio(in: .english, policy: .networkFirst)
    _ = await (fr, en)

    #expect(await client.sendCount == 2)
  }

  // ── Decoding ───────────────────────────────────────────────────────────

  @Test("maps the API's real payload into domain entities")
  func decodesRealPayload() async throws {
    let repository = makeRepository(
      client: CountingClient(response: .success(Fixtures.response(.french)))
    )

    let snapshot = try await repository.portfolio(in: .french, policy: .networkFirst)
    let portfolio = snapshot.portfolio

    #expect(!snapshot.contentVersion.isEmpty)
    #expect(portfolio.apps.ticketing.count == 33)
    #expect(portfolio.caseStudies.count >= 2)
    #expect(portfolio.experience.first?.isOngoing == true)
    #expect(portfolio.section("apps") != nil)
  }

  /// A response rendered in another language than the one asked for is an error,
  /// not a fallback: showing English to someone who asked for French is a defect
  /// you only notice in production.
  @Test("refuses a response served in the wrong language")
  func refusesWrongLanguage() async {
    let repository = makeRepository(
      client: CountingClient(response: .success(Fixtures.response(.english)))
    )

    do {
      _ = try await repository.portfolio(in: .french, policy: .networkFirst)
      Issue.record("an English response to a French request must throw")
    } catch let failure as ContentUnavailable {
      guard case .malformed(let path, _) = failure else {
        Issue.record("expected .malformed, got \(failure)")
        return
      }
      #expect(path == "meta.locale")
    } catch {
      Issue.record("unexpected error: \(error)")
    }
  }

  /// The cache stores the **bytes received**, not a re-encoding of what was
  /// decoded: re-encoding would drop any field we do not read yet, and a later
  /// version of the app would look for it in vain in a cache it impoverished
  /// itself.
  @Test("caches the received bytes verbatim")
  func cachesRawBytes() async throws {
    let store = MemoryStore()
    let received = try #require(Fixtures.payload(.french))
    let repository = makeRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      store: store
    )

    _ = try await repository.portfolio(in: .french, policy: .networkFirst)

    let key = try #require(StorageKey("portfolio-fr.json"))
    #expect(await store.read(key)?.data == received)
  }
}
