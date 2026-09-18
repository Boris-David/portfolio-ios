import Foundation

/// The in-process event bus.
///
/// An actor: `publish` may be called from any task, and the list of subscribers
/// is shared mutable state. A lock would have protected it provided everybody
/// remembered to take it; the actor makes forgetting impossible.
///
/// ## Why `AsyncStream` and not Combine
///
/// Combine would work, and it would bring a second concurrency model into a code
/// base that has exactly one. `AsyncStream` is the standard library's answer, it
/// composes with `for await`, it cancels when the task cancels, and it needs no
/// `AnyCancellable` kept alive in a property somebody will forget.
public actor EventBus: EventPublishing {
  private var continuations: [UUID: AsyncStream<AppEvent>.Continuation] = [:]

  public init() {}

  public func publish(_ event: AppEvent) {
    for continuation in continuations.values { continuation.yield(event) }
  }

  public var events: AsyncStream<AppEvent> {
    let id = UUID()
    return AsyncStream { continuation in
      continuations[id] = continuation
      // Terminating removes the subscriber. Without this the bus grows for the
      // lifetime of the process, yielding into streams nobody reads — a leak
      // that never crashes and never shows up in a profile.
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
  /// failure it guards against is invisible: if `onTermination` stopped
  /// removing subscribers, the bus would keep yielding into streams nobody
  /// reads, for the lifetime of the process. No crash, nothing in a profile,
  /// just a number going up.
  var continuationCountForTesting: Int { continuations.count }
}
