import Foundation
import Testing
@testable import Core

/// One clock protocol for the whole repository.
///
/// Before `Core`, three layers each injected `@Sendable () -> Date` — three
/// closures, three conventions, and nothing saying they meant the same thing.
/// This is the smallest illustration of why the package exists: not to collect
/// leftovers, but to stop one abstraction being written three times, slightly
/// differently each time.
struct ClockTests {
  @Test("a fixed clock does not move on its own")
  func fixedClockIsStill() {
    let clock = FixedClock(Date(timeIntervalSince1970: 1_000))
    let first = clock.now
    #expect(clock.now == first)
  }

  @Test("a fixed clock moves only when pushed")
  func fixedClockAdvances() {
    let clock = FixedClock(Date(timeIntervalSince1970: 1_000))
    clock.advance(by: 3_600)
    #expect(clock.now == Date(timeIntervalSince1970: 4_600))
  }

  /// The point of the abstraction: a cache-age test must not take a day to run.
  @Test("an age can be measured without waiting for it")
  func ageIsMeasurableInstantly() {
    let clock = FixedClock(Date(timeIntervalSince1970: 0))
    let storedAt = clock.now
    clock.advance(by: 86_400)
    #expect(clock.now.timeIntervalSince(storedAt) == 86_400)
  }
}

struct KeyValueStoreTests {
  @Test("a value written comes back")
  func roundTrip() {
    let store = InMemoryKeyValueStore()
    store.set("fr", forKey: "language")
    store.set(true, forKey: "backstage")
    #expect(store.string(forKey: "language") == "fr")
    #expect(store.bool(forKey: "backstage"))
  }

  /// A first launch has decided nothing, and the store must say so rather than
  /// invent a default — the default belongs to whoever knows what it means.
  @Test("an absent value is absent, not invented")
  func absentValues() {
    let store = InMemoryKeyValueStore()
    #expect(store.string(forKey: "language") == nil)
    #expect(store.bool(forKey: "backstage") == false)
  }

  @Test("a removed value is gone")
  func removal() {
    let store = InMemoryKeyValueStore(["language": "en"])
    store.removeValue(forKey: "language")
    #expect(store.string(forKey: "language") == nil)
  }
}

struct ConnectivityStatusTests {
  /// Three cases and not two. `unknown` is the state before the first path
  /// update lands, and treating it as offline would flash an "you are offline"
  /// banner at every launch — the classic tell of an app that feels broken
  /// before it has done anything wrong.
  @Test("not knowing is not the same as being offline")
  func unknownIsNotOffline() {
    #expect(!ConnectivityStatus.unknown.isKnownOffline)
    #expect(!ConnectivityStatus.online(isExpensive: false).isKnownOffline)
    #expect(ConnectivityStatus.offline.isKnownOffline)
  }

  @Test("a static report yields its value and then finishes")
  func staticReport() async {
    let reporting = StaticConnectivity(.offline)
    #expect(await reporting.current == .offline)

    var received: [ConnectivityStatus] = []
    for await status in await reporting.changes { received.append(status) }
    #expect(received == [.offline])
  }
}
