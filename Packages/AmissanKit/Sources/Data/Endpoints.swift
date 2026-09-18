import Domain
import Foundation

/// Où joindre la source.
///
/// Les chemins sont construits ici et nulle part ailleurs : une URL assemblée
/// au point d'appel est une URL qu'on retrouve un jour écrite à deux endroits,
/// avec un `/` de différence.
public struct Endpoints: Sendable {
  public static let production = Endpoints(
    baseURL: URL(string: "https://api.amissan.dev")!
  )

  let baseURL: URL

  public init(baseURL: URL) {
    self.baseURL = baseURL
  }

  /// La langue passe par `?lang=` — **pas** `?locale=`, que l'API ignorerait en
  /// silence en servant le français. Une requête qui se trompe de nom de
  /// paramètre répond 200 avec la mauvaise langue, et c'est la pire des
  /// réponses.
  func portfolio(in language: Language) -> URL {
    var components = URLComponents(url: baseURL.appending(path: "/v1/portfolio"), resolvingAgainstBaseURL: false)!
    components.queryItems = [URLQueryItem(name: "lang", value: language.rawValue)]
    return components.url!
  }

  /// Le CV. Le dernier segment de l'URL **est** le nom du fichier : Safari sur
  /// iOS ignore `Content-Disposition` et nomme un partage d'après lui. Servi
  /// sur `/v1/cv/fr.pdf`, le document s'appelait « fr ».
  func resume(in language: Language) -> URL {
    baseURL.appending(path: "/v1/cv/amissan.ag-cv-\(language.rawValue).pdf")
  }
}
