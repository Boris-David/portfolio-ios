import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// What he built himself, end to end.
///
/// ## Why this earns a tab
///
/// Everything else in the app is work done inside somebody else's product: a
/// ticketing layer in thirty-three transport applications, a mail client, a
/// legacy rebuild. All of it real, none of it a thing you can open.
///
/// These are his from the first line — one on the App Store, one whose three
/// repositories are public and whose store listing does not exist yet. It is
/// the only screen in the portfolio where a reader can go and use the result,
/// or read every line of it. That is worth a permanent place in the bar.
///
/// ## Two tiers, kept apart
///
/// Products first, then the open projects — a component and an interview
/// exercise, which moved here from the journey. They belong in this tab, which
/// answers "what has he built himself"; they do not belong at the same level as
/// something published, and running them together would let an exercise stand
/// next to an App Store product as though it were the same claim.
///
/// ## What it costs in new content: almost nothing
///
/// Every piece of this was already being served. `AppCatalogue.items` was only
/// ever reached through `.ticketing`, so the `end-to-end` and `features` roles
/// were displayed on no screen at all, and `kcalories.png` sat in the catalogue
/// as a dead asset. The four screenshots were published under the case study
/// and shown at the very bottom of a push two levels down.
public struct ProductScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(.product) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot.portfolio)
      }
    }
  }

  @ViewBuilder
  private func content(_ portfolio: Portfolio) -> some View {
    // Everything he owns end to end, named by the content and never by a slug
    // written here. The day a third one ships, this screen shows it without a
    // line changing.
    let products = portfolio.apps.ownedEndToEnd

    if products.isEmpty, portfolio.background.openProjects.isEmpty {
      // The catalogue published nothing in that role. Say so rather than draw an
      // empty screen — which is precisely the failure a `default:` case caused
      // on the expertise route.
      FailureView(failure: PhaseFailure(.nothingAvailable), retry: { store.load() })
    } else {
      SectionScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s7) {
          ForEach(products) { product in
            productSection(product, in: portfolio)
          }
          if !portfolio.background.openProjects.isEmpty {
            OpenProjectsBlock(projects: portfolio.background.openProjects)
          }
        }
        .padding(.top, Tokens.Space.s5)
      }
      .refreshable { await store.refresh() }
    }
  }

  /// One product: what it is, what it looks like, and how it was built.
  ///
  /// The gallery and the story are conditional because they come from a case
  /// study, and only one of these products has one. A product without a case
  /// study is not a degraded product — it is a product whose story has not been
  /// written yet, and the screen shows what exists rather than a placeholder.
  @ViewBuilder
  private func productSection(_ product: ProductionApp, in portfolio: Portfolio) -> some View {
    let study = portfolio.caseStudies.first { $0.slug == product.slug }

    VStack(alignment: .leading, spacing: Tokens.Space.s6) {
      ProductHeaderBlock(
        product: product,
        study: study,
        metric: portfolio.metrics.first { $0.caption.contains(product.name) }
      )
      if let study, !study.media.isEmpty {
        ProductGalleryBlock(media: study.media)
      }
      if let study {
        ProductStoryBlock(study: study)
      }
    }
  }
}
