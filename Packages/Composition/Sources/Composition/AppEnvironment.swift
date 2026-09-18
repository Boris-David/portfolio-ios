import Core
import Data
import Domain
import FeatureResume
import FeatureSettings
import Foundation
import Networking

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
  public let preferences: any PreferencesStoring
  public let events: any EventPublishing

  public init(
    portfolio: any PortfolioReading,
    resume: any ResumeReading,
    preferences: any PreferencesStoring,
    events: any EventPublishing
  ) {
    self.portfolio = portfolio
    self.resume = resume
    self.preferences = preferences
    self.events = events
  }

  /// The real wiring: network, disk cache, bundled seed.
  public static func live(endpoints: APIEndpoints = .production) -> AppEnvironment {
    let client = URLSessionHTTPClient(session: URLSessionHTTPClient.makeSession())
    let store = FileStore()
    // One monitor for the whole app: several of them would each keep an
    // `NWPathMonitor` alive, and the system would answer the same question
    // three times.
    let connectivity = ConnectivityMonitor()

    return AppEnvironment(
      portfolio: PortfolioRepository(
        client: client,
        store: store,
        seed: BundledSeedDataSource(),
        endpoints: endpoints,
        connectivity: connectivity
      ),
      resume: ResumeRepository(client: client, store: store, endpoints: endpoints),
      preferences: PreferencesRepository(),
      events: AppEventBus()
    )
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interface segregation: each feature states what it needs, and the composition
// root proves it can meet it.
//
// The alternative is handing `AppEnvironment` to every screen, which compiles
// and is a violation: the settings screen would then be free to reach the
// portfolio reader, and one day it would.
//
// These conformances are the whole cost — four lines — and they are checked by
// the compiler. A feature that adds a requirement breaks the build here, at the
// one place that can satisfy it.
// ─────────────────────────────────────────────────────────────────────────────

extension AppEnvironment: SettingsDependencies {}
extension AppEnvironment: ResumeDependencies {}
