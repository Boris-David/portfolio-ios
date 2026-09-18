import Domain
import Foundation

/// Where to reach the source.
///
/// Paths are built here and nowhere else: a URL assembled at the call site is a
/// URL that one day exists in two places, differing by a `/`.
public struct Endpoints: Sendable {
  public static let production = Endpoints(
    baseURL: URL(string: "https://api.amissan.dev")!
  )

  private let baseURL: URL

  public init(baseURL: URL) {
    self.baseURL = baseURL
  }

  /// The language goes through `?lang=` — **not** `?locale=`, which the API
  /// would ignore in silence while serving French. A request that gets the
  /// parameter name wrong answers 200 with the wrong language, and that is the
  /// worst kind of answer.
  func portfolio(in language: Language) -> URL {
    var components = URLComponents(url: baseURL.appending(path: "/v1/portfolio"), resolvingAgainstBaseURL: false)!
    components.queryItems = [URLQueryItem(name: "lang", value: language.rawValue)]
    return components.url!
  }

  /// The résumé. The last path component **is** the file name: Safari on iOS
  /// ignores `Content-Disposition` and names a share after it. Served from
  /// `/v1/cv/fr.pdf`, the document was called "fr".
  func resume(in language: Language) -> URL {
    baseURL.appending(path: "/v1/cv/amissan.ag-cv-\(language.rawValue).pdf")
  }
}
