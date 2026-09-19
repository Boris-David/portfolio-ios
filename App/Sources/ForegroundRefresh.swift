import Core
import Domain
import Presentation
import SwiftUI

/// Brings the content back up to date when the app comes back into view, and
/// when the network does.
///
/// ## Why this is a modifier and not three lines in `AppRoot`
///
/// Because it is three *rules*, each with a trap, and `AppRoot` has already been
/// emptied once for exactly this reason. Kept together, they can be read as one
/// policy — which is what they are.
///
/// ## The three rules
///
/// **Coming back to the foreground refreshes.** Somebody who left the app open
/// yesterday and opened it today is looking at yesterday's content with no way
/// to know. Pull-to-refresh exists, but expecting the reader to guess that the
/// screen is stale is not a design.
///
/// **The first activation does not.** `scenePhase` becomes `.active` during
/// launch, right after the initial load has already been started. Refreshing on
/// it would mean two requests every single launch — invisible on wifi, a
/// doubled bill on cellular, and a screen that rebuilds itself for no reason.
///
/// **Coming back online refreshes, once.** A path that flaps — a lift, a train
/// tunnel — would otherwise fire a request per flap. Only a transition *into*
/// reachability counts, and only from a state that was known to be down.
struct ForegroundRefresh: ViewModifier {
  let store: PortfolioStore
  let connectivity: any ConnectivityReporting
  let events: any EventPublishing

  @Environment(\.scenePhase) private var scenePhase
  @State private var hasBeenActive = false

  func body(content: Content) -> some View {
    content
      .onChange(of: scenePhase) { _, phase in
        guard phase == .active else { return }
        guard hasBeenActive else {
          // The launch activation. The first load is already in flight.
          hasBeenActive = true
          return
        }
        Task { await store.refresh() }
      }
      .task { await followConnectivity() }
  }

  private func followConnectivity() async {
    var wasReachable: Bool?
    for await status in await connectivity.changes {
      let isReachable = !status.isKnownOffline
      defer { wasReachable = isReachable }

      // Announce every change: a banner, a screen, anything that wants to know
      // subscribes to the fact rather than to the monitor.
      await events.publish(.connectivityChanged(isReachable: isReachable))

      // Refresh only on the **edge** from down to up. `nil` is the first
      // reading, which says nothing about a transition — and refreshing on it
      // would duplicate the launch load all over again.
      guard wasReachable == false, isReachable else { continue }
      await store.refresh()
    }
  }
}

extension View {
  func refreshingOnReturn(
    store: PortfolioStore,
    connectivity: any ConnectivityReporting,
    events: any EventPublishing
  ) -> some View {
    modifier(ForegroundRefresh(store: store, connectivity: connectivity, events: events))
  }
}
