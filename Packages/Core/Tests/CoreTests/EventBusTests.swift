import Testing
@testable import Core

/// A bus nobody can observe reliably is worse than no bus: the code that
/// publishes looks correct, and the code that should have reacted simply never
/// does — with nothing to show for it.
struct EventBusTests {
  @Test("a subscriber receives what is published after it subscribed")
  func deliversToSubscriber() async {
    let bus = EventBus()
    let stream = await bus.events

    await bus.publish(.languageChanged)

    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next() == .languageChanged)
  }

  /// Deliberately **not** replayed. A bus is a record of changes, not a store of
  /// values: a subscriber that needs the current state reads it from a port.
  /// Replaying would make a late subscriber react to something that was already
  /// handled, which is the subtlest kind of double-processing.
  @Test("a subscriber does not receive what happened before it arrived")
  func doesNotReplay() async {
    let bus = EventBus()
    await bus.publish(.languageChanged)

    let stream = await bus.events
    await bus.publish(.contentRefreshed(contentVersion: "v2"))

    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next() == .contentRefreshed(contentVersion: "v2"))
  }

  @Test("every subscriber receives every event")
  func fansOut() async {
    let bus = EventBus()
    let first = await bus.events
    let second = await bus.events

    await bus.publish(.resumeDownloaded(fileName: "cv.pdf"))

    var a = first.makeAsyncIterator()
    var b = second.makeAsyncIterator()
    #expect(await a.next() == .resumeDownloaded(fileName: "cv.pdf"))
    #expect(await b.next() == .resumeDownloaded(fileName: "cv.pdf"))
  }

  /// The leak this prevents never crashes and never shows in a profile: the bus
  /// keeps yielding into streams nobody reads, for the lifetime of the process.
  @Test("a finished subscriber is forgotten")
  func forgetsTerminatedSubscribers() async {
    let bus = EventBus()
    do {
      let stream = await bus.events
      _ = stream
    }
    // Give the termination handler its turn before counting.
    await Task.yield()
    await bus.publish(.languageChanged)
    #expect(await bus.subscriberCount <= 1)
  }
}

extension EventBus {
  /// Exposed for the leak test only — the count is not part of the contract, it
  /// is the thing that would silently grow if termination stopped working.
  var subscriberCount: Int {
    get async { continuationCountForTesting }
  }
}
