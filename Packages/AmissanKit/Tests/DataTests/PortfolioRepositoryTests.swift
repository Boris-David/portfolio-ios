import Domain
import Foundation
import Networking
import Testing
@testable import Data

struct PortfolioRepositoryTests {
  /// Consomme le flux sans se soucier de son issue — pour les tests qui
  /// n'observent que le **compte** de requêtes.
  private func drain(_ repository: PortfolioRepository, _ language: Language) async {
    do { for try await _ in repository.portfolio(in: language) {} } catch {}
  }

  private func collect(
    _ repository: PortfolioRepository,
    _ language: Language = .french
  ) async throws -> [PortfolioSnapshot] {
    var snapshots: [PortfolioSnapshot] = []
    for try await snapshot in repository.portfolio(in: language) { snapshots.append(snapshot) }
    return snapshots
  }

  // ── La lecture en trois couches ────────────────────────────────────────

  @Test("sert d'abord la graine, puis le réseau")
  func seedThenNetwork() async throws {
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      store: MemoryStore(),
      seed: FixtureSeed()
    )

    let snapshots = try await collect(repository)

    #expect(snapshots.count == 2)
    #expect(snapshots.first?.origin == .bundledSeed(builtAt: Date(timeIntervalSince1970: 1_600_000_000)))
    #expect(snapshots.last?.origin == .network)
  }

  @Test("préfère le cache à la graine")
  func cacheBeatsSeed() async throws {
    let cached = try #require(Fixtures.payload(.french))
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      store: MemoryStore(seeded: ["portfolio-fr.json": cached]),
      seed: FixtureSeed()
    )

    let snapshots = try await collect(repository)
    guard case .cache = snapshots.first?.origin else {
      Issue.record("le premier instantané devrait venir du cache")
      return
    }
  }

  /// Un échec réseau **n'est pas** une erreur quand on a de quoi afficher. Il
  /// devient une information portée par l'instantané.
  @Test("un échec réseau n'efface pas ce qu'on peut déjà montrer")
  func networkFailureKeepsLocal() async throws {
    let repository = PortfolioRepository(
      client: CountingClient(response: .failure(.transport(description: "hors ligne"))),
      store: MemoryStore(),
      seed: FixtureSeed()
    )

    let snapshots = try await collect(repository)

    #expect(snapshots.count == 2)
    #expect(snapshots.last?.refreshFailure == .unreachable)
    #expect(snapshots.last?.isStale == true)
  }

  /// Rien en réseau, rien en local : c'est le seul cas qui mérite un écran
  /// d'erreur plein.
  @Test("lève seulement quand il n'y a vraiment rien")
  func throwsWhenNothingAvailable() async {
    let repository = PortfolioRepository(
      client: CountingClient(response: .failure(.transport(description: "hors ligne"))),
      store: MemoryStore(),
      seed: EmptySeed()
    )

    await #expect(throws: ContentUnavailable.nothingAvailable) {
      for try await _ in repository.portfolio(in: .french) {}
    }
  }

  // ── La fusion des rafraîchissements ────────────────────────────────────

  /// **Le test le plus important de ce module.**
  ///
  /// Quatre écrans demandent le contenu en apparaissant. Sans coordination, ce
  /// sont quatre requêtes, quatre écritures de cache concurrentes, et deux
  /// versions possibles à l'écran. Personne ne le verrait — c'est précisément
  /// ce qui rend le défaut coûteux.
  @Test("quatre lectures simultanées ne font qu'une requête")
  func concurrentReadsShareOneRequest() async throws {
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = PortfolioRepository(client: client, store: MemoryStore(), seed: EmptySeed())

    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<4 {
        group.addTask { await drain(repository, .french) }
      }
    }

    #expect(await client.sendCount == 1)
  }

  @Test("deux langues demandées en même temps font deux requêtes")
  func languagesAreNotShared() async throws {
    let client = CountingClient(response: .success(Fixtures.response(.french)))
    let repository = PortfolioRepository(client: client, store: MemoryStore(), seed: EmptySeed())

    async let fr: Void = drain(repository, .french)
    async let en: Void = drain(repository, .english)
    _ = await (fr, en)

    #expect(await client.sendCount == 2)
  }

  // ── Le décodage, et ses erreurs ────────────────────────────────────────

  @Test("adapte la charge réelle de l'API en entités du domaine")
  func decodesRealPayload() async throws {
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      store: MemoryStore(),
      seed: EmptySeed()
    )

    let snapshot = try #require(try await collect(repository).last)
    let portfolio = snapshot.portfolio

    #expect(!snapshot.contentVersion.isEmpty)
    #expect(portfolio.apps.ticketing.count == 33)
    #expect(portfolio.caseStudies.count >= 2)
    #expect(portfolio.experience.first?.isOngoing == true)
    #expect(portfolio.section("apps") != nil)
  }

  /// Le `codingPath` de `DecodingError` donne gratuitement le chemin du champ
  /// fautif. Un « contenu invalide » sans lieu n'aide personne.
  @Test("nomme le chemin exact du champ manquant")
  func namesMissingField() async {
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.responseMissing(["data", "profile"]))),
      store: MemoryStore(),
      seed: EmptySeed()
    )

    do {
      for try await _ in repository.portfolio(in: .french) {}
      Issue.record("une charge amputée devrait lever")
    } catch let failure as ContentUnavailable {
      guard case .malformed(let path, _) = failure else {
        Issue.record("attendu `malformed`, reçu \(failure)")
        return
      }
      #expect(path.contains("profile"))
    } catch {
      Issue.record("erreur inattendue : \(error)")
    }
  }

  /// Une réponse rendue dans une autre langue que celle demandée est une
  /// erreur, pas un repli : afficher l'anglais à qui a demandé le français est
  /// une panne qu'on ne voit qu'une fois en production.
  @Test("refuse une réponse rendue dans la mauvaise langue")
  func refusesWrongLanguage() async {
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.response(.english))),
      store: MemoryStore(),
      seed: EmptySeed()
    )

    do {
      for try await _ in repository.portfolio(in: .french) {}
      Issue.record("une réponse en anglais pour une demande en français devrait lever")
    } catch let failure as ContentUnavailable {
      guard case .malformed(let path, _) = failure else {
        Issue.record("attendu `malformed`, reçu \(failure)")
        return
      }
      #expect(path == "meta.locale")
    } catch {
      Issue.record("erreur inattendue : \(error)")
    }
  }

  /// Le cache reçoit les **octets reçus**, pas un ré-encodage : ré-encoder
  /// perdrait tout champ qu'on ne lit pas encore, et une version ultérieure de
  /// l'application le chercherait en vain dans un cache qu'elle a appauvri.
  @Test("met en cache les octets reçus, tels quels")
  func cachesRawBytes() async throws {
    let store = MemoryStore()
    let received = try #require(Fixtures.payload(.french))
    let repository = PortfolioRepository(
      client: CountingClient(response: .success(Fixtures.response(.french))),
      store: store,
      seed: EmptySeed()
    )

    _ = try await collect(repository)

    let key = try #require(StorageKeyForTests.portfolioFR)
    #expect(await store.read(key)?.data == received)
  }
}

import Persistence
enum StorageKeyForTests {
  static let portfolioFR = StorageKey("portfolio-fr.json")
}
