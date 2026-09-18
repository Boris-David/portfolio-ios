import Foundation

/// The transport implementation, on `URLSession`.
///
/// A `struct` and not an `actor`: it holds no mutable state. `URLSession` is
/// `Sendable` and manages its own queue. An actor here would serialise requests
/// that have every reason to leave in parallel — an actor is not a safety
/// sticker you apply out of caution, it is a serialisation, and it is paid for.
public struct URLSessionHTTPClient: HTTPClient {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  /// The app's configuration.
  ///
  /// `URLSession`'s cache is **off**: content freshness is decided by the `Data`
  /// layer, with the `ETag` and the on-disk copy. Two stacked caches means stale
  /// content nobody can attribute, and a `304` you never see because a cache
  /// underneath already answered.
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
      // On a 304 there is no useful body: returning a URL to an empty file
      // would invite somebody to open it.
      temporaryURL: response.statusCode == 304 ? nil : url
    )
  }

  // ───────────────────────────────────────────────────────────────────────
  // The common trunk: build the request, translate the failures.
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
      // A cancellation is not a failure: it travels up as-is, to somebody who
      // knows why they cancelled.
      throw HTTPError.transport(description: "cancelled")
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
