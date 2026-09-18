import Data
import Domain
import Foundation
import Networking
import Persistence

/// Everything the app needs in order to run, as one value.
///
/// ## Why not a dependency-injection container
///
/// A container — type registration, resolution by key — brings two things: lazy
/// resolution, and scattered registration. Neither is an advantage here:
///
/// - **lazy**: three objects, built in microseconds. Nothing to gain;
/// - **scattered**: that is precisely what we do not want. Registration spread
///   around means you can no longer tell, by reading, what answers what — and a
///   missing resolution only shows up at runtime.
///
/// A three-field struct built at launch gives the opposite: the whole graph
/// reads in ten lines, and **the compiler** guarantees it is complete.
public struct AppEnvironment: Sendable {
  public let portfolio: any PortfolioReading
  public let resume: any ResumeReading
  public let language: Language

  public init(portfolio: any PortfolioReading, resume: any ResumeReading, language: Language) {
    self.portfolio = portfolio
    self.resume = resume
    self.language = language
  }

  /// The real wiring: network, disk cache, bundled seed.
  public static func live(
    endpoints: Endpoints = .production,
    language: Language = .preferred()
  ) -> AppEnvironment {
    let client = URLSessionHTTPClient(session: URLSessionHTTPClient.makeSession())
    let store = FileStore()

    return AppEnvironment(
      portfolio: PortfolioRepository(
        client: client,
        store: store,
        seed: BundledSeed(),
        endpoints: endpoints
      ),
      resume: ResumeRepository(client: client, store: store, endpoints: endpoints),
      language: language
    )
  }
}

public extension Language {
  /// The device's language, when the source serves it.
  ///
  /// Kept only as a bridge while the settings screen lands. Resolution is owned
  /// by `LanguagePreference.resolved(systemLanguages:)` — including the fallback
  /// to **English**, which is a product decision and has no business living on
  /// the `Language` type itself.
  static func preferred() -> Language {
    LanguagePreference.system.resolved(systemLanguages: Foundation.Locale.preferredLanguages)
  }
}
