import Foundation
import Network

/// `NWPathMonitor`, behind the port.
///
/// The **one** place in the repository that names `Network.framework`.
///
/// An actor because `NWPathMonitor` delivers its updates on a queue of its own,
/// and several screens may subscribe at once: the status and the list of
/// continuations are shared mutable state, which is exactly what an actor makes
/// safe by construction rather than by review.
public actor ConnectivityMonitor: ConnectivityReporting {
  private let monitor = NWPathMonitor()
  private var status: ConnectivityStatus = .unknown
  private var continuations: [UUID: AsyncStream<ConnectivityStatus>.Continuation] = [:]
  private var isStarted = false

  public init() {}

  public var current: ConnectivityStatus {
    start()
    return status
  }

  public var changes: AsyncStream<ConnectivityStatus> {
    start()
    let id = UUID()
    return AsyncStream { continuation in
      continuations[id] = continuation
      // The current value first: a subscriber that had to wait for the network
      // to move before it could draw would draw nothing on a stable connection.
      continuation.yield(status)
      continuation.onTermination = { [weak self] _ in
        Task { await self?.forget(id) }
      }
    }
  }

  private func start() {
    guard !isStarted else { return }
    isStarted = true
    monitor.pathUpdateHandler = { [weak self] path in
      let status: ConnectivityStatus = switch path.status {
      case .satisfied: .online(isExpensive: path.isExpensive)
      case .unsatisfied, .requiresConnection: .offline
      @unknown default: .unknown
      }
      Task { await self?.update(status) }
    }
    monitor.start(queue: DispatchQueue(label: "dev.amissan.connectivity"))
  }

  private func update(_ new: ConnectivityStatus) {
    guard new != status else { return }
    status = new
    for continuation in continuations.values { continuation.yield(new) }
  }

  private func forget(_ id: UUID) {
    continuations[id] = nil
  }
}
