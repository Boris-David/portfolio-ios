import Foundation

/// An HTTP request, described as a value.
///
/// No mutable "request object" configured in steps: a value is `Sendable` for
/// free, compares in a test, and cannot change between the moment it is built
/// and the moment it is sent.
public struct HTTPRequest: Sendable, Hashable {
  public enum Method: String, Sendable, Hashable {
    case get = "GET"
  }

  public let method: Method
  public let url: URL
  public let headers: [String: String]

  public init(method: Method = .get, url: URL, headers: [String: String] = [:]) {
    self.method = method
    self.url = url
    self.headers = headers
  }

  /// The same request, conditioned on a known entity tag.
  ///
  /// This is what makes coming back to the app **free**: the server answers
  /// `304` and not one byte of body crosses the network.
  public func revalidating(entityTag: String?) -> HTTPRequest {
    guard let entityTag, !entityTag.isEmpty else { return self }
    var headers = self.headers
    headers["If-None-Match"] = entityTag
    return HTTPRequest(method: method, url: url, headers: headers)
  }
}
