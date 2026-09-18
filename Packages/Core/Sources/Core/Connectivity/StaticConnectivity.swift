/// A connectivity report that never changes — for tests and previews.
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
