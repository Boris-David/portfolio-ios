import FeatureArchitecture
import FeatureKit
import FeatureProfile
import FeatureWork
import Presentation
import SwiftUI
import ViewKit

/// Turns a route into a screen — the one thing the features cannot do
/// themselves, since they do not know each other.
///
/// ⚠️ **No `default:`.** There was one, and it answered `EmptyView()` — so
/// `expertise`, which the profile screen pushes when a reader touches one of the
/// three depth topics, opened a black screen with a back button and nothing
/// else. Nothing failed; the screen was simply empty. The switch is exhaustive
/// now, and a new route does not compile until it has something to draw.
///
/// `FeatureProfile` has to be able to open the KCalories case study: the card on
/// the home screen links to it. That study lives in `FeatureWork`, and the two
/// modules are **siblings** — neither may import the other, which is exactly
/// what we want. So each feature declares a *value*, and this resolver, in the
/// only module that sees everything, turns it into a view.
struct RouteScreen: View {
  let route: Route
  let zoom: Namespace.ID

  @Environment(PortfolioStore.self) private var store

  var body: some View {
    switch route {
    case .caseStudy(let slug):
      if let study = store.portfolio?.caseStudies.first(where: { $0.slug == slug }) {
        CaseStudyDetailScreen(study: study)
          // The other half of the zoom. `.zoom` needs both a source and a
          // destination naming the same identity; with only one, the push
          // silently falls back to the default slide.
          .navigationTransition(.zoom(sourceID: slug, in: zoom))
      } else {
        // A route to content that is not there — which happens with a deep link
        // received before the first load. Say so; do not show a blank screen.
        RouteMissingView()
      }
    case .about:
      if let profile = store.portfolio?.profile {
        AboutScreen(profile: profile)
      } else {
        missing
      }

    case .architectures:
      if let study = store.portfolio?.architectures {
        ArchitectureScreen(study: study)
      } else {
        missing
      }

    case .expertise(let id):
      if let topic = store.portfolio?.expertise.first(where: { $0.id == id }) {
        // The dive may legitimately be absent — a topic published before its
        // essay. The screen then shows the topic alone, which is what the
        // profile already said, rather than a blank page.
        DeepDiveScreen(topic: topic, dive: store.portfolio?.deepDive(for: id))
      } else {
        missing
      }
    }
  }

  /// A route to content that is not there — which happens with a deep link
  /// received before the first load. Say so; do not show a blank screen.
  private var missing: some View { RouteMissingView() }
}

extension RouteResolver {
  /// The resolution the application installs into the environment.
  ///
  /// It takes the zoom namespace because the two halves of that transition live
  /// in two different features: the card is in `FeatureWork`, the destination is
  /// resolved here. Neither can own the namespace, so the place that sees both
  /// does.
  @MainActor
  static func live(in zoom: Namespace.ID) -> RouteResolver {
    RouteResolver { route in
      AnyView(RouteScreen(route: route, zoom: zoom))
    }
  }
}
