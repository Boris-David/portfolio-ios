import Foundation

/// An in-process publish/subscribe bus, **generic over what it carries**.
///
/// ## Why generic, and why that mattered
///
/// The first version declared its own `AppEvent` — `contentRefreshed`,
/// `languageChanged`. That put the application's vocabulary inside the mechanics
/// package, and it had a consequence nobody would have predicted: every layer
/// that wanted to *subscribe* had to depend on `Core`, and therefore gained
/// access to `FileStore`. A screen could have read the cache directly.
///
/// One generic parameter closes that. `Core` provides the machine and knows
/// nothing; `Domain` owns the vocabulary (`AppEvent`) and the port
/// (`EventPublishing`); `Data` declares the conformance that joins them. Nobody
/// gains a dependency they did not need.
///
/// ## An actor, not a lock
///
/// `publish` may be called from any task, and the subscriber list is shared
/// mutable state. A lock would protect it provided everybody remembered to take
/// it; the actor makes forgetting impossible.
///
/// ## `AsyncStream` and not Combine
///
/// Combine would work and would bring a second concurrency model into a code
/// base that has one. `AsyncStream` composes with `for await`, cancels when the
/// task cancels, and needs no `AnyCancellable` held alive in a property somebody
/// will forget.
public actor EventBus<Event: Sendable> {
  private var continuations: [UUID: AsyncStream<Event>.Continuation] = [:]

  public init() {}

  public func publish(_ event: Event) {
    for continuation in continuations.values { continuation.yield(event) }
  }

  /// Every event from the moment of subscription.
  ///
  /// Deliberately **not** replayed: a bus is a record of changes, not a store of
  /// values. A late subscriber replaying history would react to something
  /// already handled, which is the subtlest kind of double-processing.
  public var events: AsyncStream<Event> {
    let id = UUID()
    return AsyncStream { continuation in
      continuations[id] = continuation
      // Without this the bus grows for the lifetime of the process, yielding
      // into streams nobody reads — a leak that never crashes and never shows
      // up in a profile.
      continuation.onTermination = { [weak self] _ in
        Task { await self?.forget(id) }
      }
    }
  }

  private func forget(_ id: UUID) {
    continuations[id] = nil
  }

  /// How many subscribers are held right now.
  ///
  /// Not part of the contract — nothing in the app asks. It exists because the
  /// failure it guards against is invisible: if `onTermination` stopped removing
  /// subscribers, nothing would break, a number would simply go up.
  var continuationCountForTesting: Int { continuations.count }
}
