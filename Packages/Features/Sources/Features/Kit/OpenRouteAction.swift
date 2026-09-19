import Presentation
import SwiftUI

/// Opens a reading — by pushing it, or by presenting it when the stack is
/// already deep.
///
/// ## Why every screen goes through this and none decides for itself
///
/// Because the rule is about the **stack**, and a card does not know how deep
/// it is. `NavigationLink(value:)` cannot know either: it appends to the path
/// and that is the whole of its behaviour, which is why the sites that used one
/// are buttons now.
///
/// The rule itself: two pushes is a detour a reader can see their way out of;
/// the third is a corridor. Past it, the reading is presented — one way out,
/// and it says so.
package struct OpenRouteAction: Sendable {
  private let open: @MainActor @Sendable (Route) -> Void

  // `package` and not `public`: the decision is taken inside the features
  // package and consumed there. The composition root never opens a route — it
  // resolves one.

  package init(_ open: @escaping @MainActor @Sendable (Route) -> Void) {
    self.open = open
  }

  @MainActor
  package func callAsFunction(_ route: Route) { open(route) }
}

package extension EnvironmentValues {
  /// Does nothing by default — a screen wired without it shows links that
  /// respond to nothing, which is visible on the first tap.
  @Entry var openRoute = OpenRouteAction { _ in }
}
