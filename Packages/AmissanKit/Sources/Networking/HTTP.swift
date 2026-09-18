import Foundation

/// Une requête HTTP, décrite comme une valeur.
///
/// Pas d'« objet requête » mutable qu'on configure par étapes : une valeur est
/// `Sendable` sans effort, se compare dans un test, et ne peut pas être
/// modifiée entre le moment où on la construit et celui où on l'envoie.
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

  /// La même requête, conditionnée par une empreinte connue.
  ///
  /// C'est ce qui rend un retour dans l'application **gratuit** : le serveur
  /// répond `304` et pas un octet de corps ne traverse le réseau.
  public func revalidating(entityTag: String?) -> HTTPRequest {
    guard let entityTag, !entityTag.isEmpty else { return self }
    var headers = self.headers
    headers["If-None-Match"] = entityTag
    return HTTPRequest(method: method, url: url, headers: headers)
  }
}

/// Une réponse HTTP, corps compris.
public struct HTTPResponse: Sendable, Hashable {
  public let status: Int
  public let headers: HTTPHeaders
  public let body: Data

  public init(status: Int, headers: HTTPHeaders, body: Data) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  public var isSuccess: Bool { (200..<300).contains(status) }
  /// Le contenu n'a pas changé : ce qu'on a en cache est encore bon.
  public var isNotModified: Bool { status == 304 }
}

/// Les en-têtes, **insensibles à la casse** — comme la norme l'exige.
///
/// Un simple `[String: String]` se serait fait avoir : `URLSession` rend
/// `Content-Disposition` sur certains serveurs et `content-disposition` sur
/// d'autres, et un jour la lecture renvoie `nil` sans que rien n'ait changé
/// chez nous. C'est le genre de bogue qu'on ne reproduit pas.
public struct HTTPHeaders: Sendable, Hashable {
  private let storage: [String: String]

  public init(_ fields: [String: String]) {
    storage = Dictionary(
      fields.map { ($0.key.lowercased(), $0.value) },
      uniquingKeysWith: { _, last in last }
    )
  }

  public subscript(name: String) -> String? {
    storage[name.lowercased()]
  }

  public var entityTag: String? { self["ETag"] }
}
