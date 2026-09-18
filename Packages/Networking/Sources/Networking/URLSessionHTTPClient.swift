import Foundation

/// L'implémentation du transport, sur `URLSession`.
///
/// Une `struct` et non un `actor` : elle ne porte aucun état mutable.
/// `URLSession` est `Sendable` et gère elle-même sa file. Mettre un acteur ici
/// sérialiserait des requêtes qui ont tout intérêt à partir en parallèle — un
/// acteur n'est pas un label de sûreté qu'on colle par précaution, c'est une
/// sérialisation, et elle se paie.
public struct URLSessionHTTPClient: HTTPClient {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  /// La configuration de l'application.
  ///
  /// Le cache d'`URLSession` est **désactivé** : la fraîcheur du contenu est
  /// décidée par la couche `Data`, avec l'`ETag` et le cache sur disque. Deux
  /// caches empilés, c'est un contenu périmé qu'on ne sait plus attribuer, et
  /// un `304` qu'on ne voit jamais parce qu'un cache en dessous a déjà répondu.
  public static func makeSession(timeout: TimeInterval = 15) -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.timeoutIntervalForRequest = timeout
    configuration.waitsForConnectivity = false
    return URLSession(configuration: configuration)
  }

  public func send(_ request: HTTPRequest) async throws(HTTPError) -> HTTPResponse {
    let (data, response) = try await perform(request) { urlRequest in
      try await session.data(for: urlRequest)
    }
    return HTTPResponse(
      status: response.statusCode,
      headers: HTTPHeaders(headerFields(of: response)),
      body: data
    )
  }

  public func download(_ request: HTTPRequest) async throws(HTTPError) -> HTTPDownload {
    let (url, response) = try await perform(request) { urlRequest in
      try await session.download(for: urlRequest)
    }
    return HTTPDownload(
      status: response.statusCode,
      headers: HTTPHeaders(headerFields(of: response)),
      // Sur un 304 il n'y a pas de corps utile : rendre une URL vers un fichier
      // vide inviterait à l'ouvrir.
      temporaryURL: response.statusCode == 304 ? nil : url
    )
  }

  // ───────────────────────────────────────────────────────────────────────
  // Le tronc commun : construire la requête, traduire les erreurs.
  // ───────────────────────────────────────────────────────────────────────

  private func perform<Payload: Sendable>(
    _ request: HTTPRequest,
    _ work: (URLRequest) async throws -> (Payload, URLResponse)
  ) async throws(HTTPError) -> (Payload, HTTPURLResponse) {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue
    for (name, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: name)
    }

    do {
      let (payload, response) = try await work(urlRequest)
      guard let http = response as? HTTPURLResponse else { throw HTTPError.notHTTP }
      return (payload, http)
    } catch let error as HTTPError {
      throw error
    } catch is CancellationError {
      // Une annulation n'est pas une panne : elle remonte telle quelle plus
      // haut, où quelqu'un sait pourquoi il a annulé.
      throw HTTPError.transport(description: "annulée")
    } catch {
      throw HTTPError.transport(description: (error as NSError).localizedDescription)
    }
  }

  private func headerFields(of response: HTTPURLResponse) -> [String: String] {
    var fields: [String: String] = [:]
    for (name, value) in response.allHeaderFields {
      guard let name = name as? String, let value = value as? String else { continue }
      fields[name] = value
    }
    return fields
  }
}
