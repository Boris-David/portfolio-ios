/// A connectivity report that never changes.
///
/// Two uses, and the second is the one the name has to survive: it is the double
/// tests and previews inject, **and** it is the null object
/// `PortfolioRepository` falls back to when nobody supplies a real reporter.
/// Naming it `ConnectivityStub` would have been honest about half of that and a
/// lie about the other half — a "stub" wired into production is how a double
/// ends up shipped.
///
/// It says what it does: the status is fixed at construction and the stream
/// yields it once, then finishes.
public struct StaticConnectivity: ConnectivityReporting {
  private let status: ConnectivityStatus

  public init(_ status: ConnectivityStatus) {
    self.status = status
  }

  public var current: ConnectivityStatus { status }

  public var changes: AsyncStream<ConnectivityStatus> {
    let status = status
    return AsyncStream { continuation in
      continuation.yield(status)
      continuation.finish()
    }
  }
}
