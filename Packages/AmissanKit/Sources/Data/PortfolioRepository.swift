import Domain
import Foundation
import Networking
import Persistence

/// Le contenu, servi d'abord depuis ce qu'on a, puis rafraîchi.
///
/// ## Les trois couches, dans cet ordre
///
/// 1. **le cache disque** — ce que la dernière session a rapporté ;
/// 2. **la graine embarquée** — produite à la construction depuis la source, et
///    qui fait qu'un tout premier lancement sans réseau affiche quelque chose ;
/// 3. **le réseau** — la vérité, quand il répond.
///
/// L'écran n'attend jamais le réseau pour s'afficher. Il montre ce qu'il a,
/// puis se met à jour — et **dit** ce qu'il montre, parce qu'une application
/// hors ligne qui ne l'avoue pas affiche du vieux contenu avec l'aplomb du neuf.
///
/// ## Pourquoi un acteur, et pas un verrou
///
/// Deux écrans qui apparaissent en même temps demandent le contenu en même
/// temps. Sans coordination, ce sont deux requêtes, deux écritures de cache
/// concurrentes, et deux versions possibles à l'écran.
///
/// La correction n'est pas de verrouiller : c'est de **mémoriser la tâche de
/// rafraîchissement en cours**. Les appels concurrents n'en lancent pas une
/// nouvelle, ils attendent la même. Un seul aller-retour, quel que soit le
/// nombre de demandeurs.
///
/// Un verrou aurait protégé l'état à condition qu'on pense à le prendre
/// partout — rien ne le vérifie — et un verrou tenu pendant une attente
/// asynchrone est un blocage qui n'attend que son heure. Avec un acteur,
/// l'isolation est une **propriété du type** : le compilateur refuse l'accès
/// non sérialisé, et l'oubli devient impossible.
public actor PortfolioRepository: PortfolioReading {
  private let client: any HTTPClient
  private let store: any LocalStore
  private let endpoints: Endpoints
  private let seed: any SeedProviding
  private let clock: @Sendable () -> Date

  /// Le rafraîchissement en cours, par langue. C'est **toute** la coordination.
  private var refreshes: [Language: Task<Loaded, any Error>] = [:]

  public init(
    client: any HTTPClient,
    store: any LocalStore,
    seed: any SeedProviding,
    endpoints: Endpoints = .production,
    clock: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.client = client
    self.store = store
    self.seed = seed
    self.endpoints = endpoints
    self.clock = clock
  }

  public nonisolated func portfolio(
    in language: Language
  ) -> AsyncThrowingStream<PortfolioSnapshot, any Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        await self.stream(language, into: continuation)
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  // ───────────────────────────────────────────────────────────────────────

  private func stream(
    _ language: Language,
    into continuation: AsyncThrowingStream<PortfolioSnapshot, any Error>.Continuation
  ) async {
    let local = await localSnapshot(for: language)
    if let local {
      continuation.yield(local)
    }

    do {
      let fresh = try await refreshed(language)

      // On émet **toujours** l'instantané réseau, même quand l'empreinte n'a
      // pas bougé.
      //
      // La première version ne le faisait pas, pour éviter de reconstruire une
      // interface identique. Le résultat se voyait à l'écran : le bandeau
      // continuait d'annoncer « contenu enregistré » alors que la source venait
      // de confirmer que ce contenu était à jour. Une optimisation qui fait
      // mentir l'interface n'est pas une optimisation.
      //
      // Et elle ne coûte rien : `Portfolio` est `Equatable`, donc SwiftUI ne
      // rediffuse que ce qui a réellement changé — ici, la seule provenance.
      continuation.yield(
        PortfolioSnapshot(
          portfolio: fresh.portfolio,
          contentVersion: fresh.contentVersion,
          origin: .network
        )
      )
      continuation.finish()
    } catch {
      let failure = contentFailure(from: error)

      guard let local else {
        // Rien en réseau, rien en local : c'est le seul cas qui mérite un écran
        // d'erreur plein.
        continuation.finish(throwing: local == nil && isNothingAvailable(failure)
          ? ContentUnavailable.nothingAvailable
          : failure)
        return
      }

      // On a de quoi afficher : l'échec n'est pas une erreur du flux, c'est une
      // information sur ce qui est affiché.
      continuation.yield(
        PortfolioSnapshot(
          portfolio: local.portfolio,
          contentVersion: local.contentVersion,
          origin: local.origin,
          refreshFailure: failure
        )
      )
      continuation.finish()
    }
  }

  /// Le rafraîchissement, **partagé** entre tous les appelants simultanés.
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
      // Le cache s'écrit avec les octets **reçus**, pas avec un ré-encodage de
      // ce qu'on a décodé : ré-encoder perdrait tout champ qu'on ne lit pas
      // encore, et une version ultérieure de l'application le chercherait en
      // vain dans un cache qu'elle a elle-même appauvri.
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

  // ── Décodage ───────────────────────────────────────────────────────────

  struct Loaded: Sendable {
    let portfolio: Portfolio
    let contentVersion: String
  }

  static func decode(_ data: Foundation.Data, expecting language: Language) throws -> Loaded {
    let envelope: PortfolioEnvelopeDTO
    do {
      envelope = try JSONDecoder().decode(PortfolioEnvelopeDTO.self, from: data)
    } catch let error as DecodingError {
      // `DecodingError` porte déjà le chemin du champ fautif : le traduire, c'est
      // obtenir gratuitement le diagnostic qu'on aurait sinon écrit à la main.
      throw ContentUnavailable.malformed(path: path(of: error), reason: reason(of: error))
    }

    // Une réponse rendue dans une autre langue que celle demandée est une
    // erreur, pas un repli : afficher l'anglais à qui a demandé le français est
    // une panne qu'on ne voit qu'une fois en production.
    guard envelope.meta.locale == language.rawValue else {
      throw ContentUnavailable.malformed(
        path: "meta.locale",
        reason: "réponse en « \(envelope.meta.locale) » alors que « \(language.rawValue) » était demandé"
      )
    }

    do {
      return Loaded(
        portfolio: try PortfolioMapping.portfolio(from: envelope.data),
        contentVersion: envelope.meta.contentVersion
      )
    } catch let error as MappingError {
      throw ContentUnavailable.malformed(path: error.path, reason: error.reason)
    }
  }

  static func cacheKey(for language: Language) -> StorageKey? {
    StorageKey("portfolio-\(language.rawValue).json")
  }

  // ── Traduction des erreurs ─────────────────────────────────────────────

  private func contentFailure(from error: any Error) -> ContentUnavailable {
    switch error {
    case let unavailable as ContentUnavailable: unavailable
    case is HTTPError: .unreachable
    default: .unreachable
    }
  }

  private func isNothingAvailable(_ failure: ContentUnavailable) -> Bool {
    if case .malformed = failure { false } else { true }
  }

  private static func path(of error: DecodingError) -> String {
    let keys: [CodingKey] = switch error {
    case .keyNotFound(let key, let context): context.codingPath + [key]
    case .typeMismatch(_, let context), .valueNotFound(_, let context),
         .dataCorrupted(let context): context.codingPath
    @unknown default: []
    }
    return keys.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }
      .joined()
      .trimmingCharacters(in: CharacterSet(charactersIn: "."))
  }

  private static func reason(of error: DecodingError) -> String {
    switch error {
    case .keyNotFound: "champ absent"
    case .typeMismatch(let type, _): "type inattendu, \(type) attendu"
    case .valueNotFound(let type, _): "valeur nulle, \(type) attendu"
    case .dataCorrupted(let context): context.debugDescription
    @unknown default: "charge utile illisible"
    }
  }
}

/// D'où vient la graine embarquée.
///
/// Un port plutôt qu'un accès direct au bundle : les tests doivent pouvoir
/// décrire un premier lancement sans réseau **et** sans fichier, ce qu'un
/// `Bundle.main` en dur rendrait impossible.
public protocol SeedProviding: Sendable {
  func data(for language: Language) -> Foundation.Data?
  var builtAt: Date { get }
}
