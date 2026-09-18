import Backstage
import DesignSystem
import Presentation
import SwiftUI

/// Who knows how to build a route's screen.
///
/// ## The problem it solves
///
/// `FeatureProfile` has to be able to open the KCalories case study — the home
/// screenshot links to it. But that study lives in `FeatureWork`, and the two
/// modules are **siblings**: neither can import the other, and that is exactly
/// what we want. Two features that know each other end up impossible to ship
/// apart.
///
/// Three ways out:
///
/// 1. *merge the two modules* — the boundary is lost for the sake of one link;
/// 2. *lift the views into `FeatureKit`* — everything ends up in the shared
///    module, which becomes the monolith we were avoiding;
/// 3. **inject the resolution** — each feature declares a route *value*, and the
///    composition root, the only place that sees everything, supplies the means
///    of turning it into a view.
///
/// This is the third. The price is one `AnyView` at the navigation boundary: one
/// indirection per push, on a path that is neither hot nor frequent.
public struct RouteDestinations: Sendable {
  private let build: @MainActor @Sendable (Route) -> AnyView

  public init(build: @escaping @MainActor @Sendable (Route) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ route: Route) -> AnyView {
    build(route)
  }
}

public extension EnvironmentValues {
  /// Nothing by default — an app that forgot to wire the resolution would show
  /// empty screens, which is obvious on the very first try.
  @Entry var routeDestinations = RouteDestinations { _ in AnyView(EmptyView()) }
}
