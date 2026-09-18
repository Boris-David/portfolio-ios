import FeatureKit
import FeatureProfile
import FeatureWork
import Presentation
import SwiftUI
import ViewKit

/// Turns a route into a screen — the one thing the features cannot do
/// themselves, since they do not know each other.
///
/// `FeatureProfile` has to be able to open the KCalories case study: the card on
/// the home screen links to it. That study lives in `FeatureWork`, and the two
/// modules are **siblings** — neither may import the other, which is exactly
/// what we want. So each feature declares a *value*, and this resolver, in the
/// only module that sees everything, turns it into a view.
struct RouteScreen: View {
  let route: Route

  @Environment(PortfolioStore.self) private var store
  @Chrome private var chrome

  var body: some View {
    switch route {
    case .caseStudy(let slug):
      if let study = store.portfolio?.caseStudies.first(where: { $0.slug == slug }) {
        CaseStudyDetailScreen(study: study)
      } else {
        // A route to content that is not there — which happens with a deep link
        // received before the first load. Say so; do not show a blank screen.
        // The glyph name never leaves `ViewKit`: this asks for the *meaning*
        // and lets the view layer draw it.
        ContentUnavailableView {
          Label(chrome.routeMissingTitle, icon: .empty)
        } description: {
          Text(chrome.routeMissingMessage)
        }
      }
    case .about:
      if let profile = store.portfolio?.profile {
        AboutScreen(profile: profile)
      } else {
        missing
      }

    default:
      EmptyView()
    }
  }

  /// A route to content that is not there — which happens with a deep link
  /// received before the first load. Say so; do not show a blank screen.
  private var missing: some View {
    ContentUnavailableView {
      Label(chrome.routeMissingTitle, icon: .empty)
    } description: {
      Text(chrome.routeMissingMessage)
    }
  }
}

extension RouteResolver {
  /// The resolution the application installs into the environment.
  @MainActor
  static let live = RouteResolver { route in
    AnyView(RouteScreen(route: route))
  }
}
