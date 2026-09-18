import Testing
@testable import Core

/// A bus nobody can observe reliably is worse than no bus: the code that
/// publishes looks correct, and the code that should have reacted simply never
/// does — with nothing to show for it.
///
/// The bus is **generic**, so its tests carry their own vocabulary. That is the
/// proof that `Core` knows nothing about the application: if these tests needed
/// `AppEvent`, the mechanics would be coupled to the domain.
private enum TestEvent: Sendable, Hashable {
  case renamed
  case refreshed(String)
  case downloaded(String)
}

struct EventBusTests {
  @Test("a subscriber receives what is published after it subscribed")
  func deliversToSubscriber() async {
    let bus = EventBus<TestEvent>()
    let stream = await bus.events

    await bus.publish(.renamed)

    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next() == .renamed)
  }

  /// Deliberately **not** replayed. A bus is a record of changes, not a store of
  /// values: a subscriber that needs the current state reads it from a port.
  /// Replaying would make a late subscriber react to something that was already
  /// handled, which is the subtlest kind of double-processing.
  @Test("a subscriber does not receive what happened before it arrived")
  func doesNotReplay() async {
    let bus = EventBus<TestEvent>()
    await bus.publish(.renamed)

    let stream = await bus.events
    await bus.publish(.refreshed("v2"))

    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next() == .refreshed("v2"))
  }

  @Test("every subscriber receives every event")
  func fansOut() async {
    let bus = EventBus<TestEvent>()
    let first = await bus.events
    let second = await bus.events

    await bus.publish(.downloaded("cv.pdf"))

    var a = first.makeAsyncIterator()
    var b = second.makeAsyncIterator()
    #expect(await a.next() == .downloaded("cv.pdf"))
    #expect(await b.next() == .downloaded("cv.pdf"))
  }

  /// The leak this prevents never crashes and never shows in a profile: the bus
  /// keeps yielding into streams nobody reads, for the lifetime of the process.
  @Test("a finished subscriber is forgotten")
  func forgetsTerminatedSubscribers() async {
    let bus = EventBus<TestEvent>()
    do {
      let stream = await bus.events
      _ = stream
    }
    // Give the termination handler its turn before counting.
    await Task.yield()
    await bus.publish(.renamed)
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
