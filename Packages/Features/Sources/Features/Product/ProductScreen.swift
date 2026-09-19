import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The one application he took end to end — four stacks, alone, in five months.
///
/// ## Why this earns a tab
///
/// Everything else in the app is work done inside somebody else's product: a
/// ticketing layer in thirty-three transport applications, a mail client, a
/// legacy rebuild. All of it real, none of it a thing you can open.
///
/// This is the one that is his from the first line to the App Store listing,
/// and it is the only screen in the portfolio where a reader can go and use the
/// result. That is worth a permanent place in the bar.
///
/// ## What it costs in new content: nothing
///
/// Every piece of this was already being served and rendered by nobody.
/// `AppCatalogue.items` was only ever reached through `.ticketing`, so the
/// `end-to-end` and `features` roles were displayed on no screen at all, and
/// `kcalories.png` sat in the catalogue as a dead asset. The four screenshots
/// were published under the case study and shown at the very bottom of a push
/// two levels down. This screen does not add a sentence; it stops hiding them.
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
    // The product is whichever app he owns end to end, named by the content and
    // never by a slug written here. The day a second one ships, this screen
    // shows it without a line changing.
    if let product = portfolio.apps.ownedEndToEnd.first {
      let study = portfolio.caseStudies.first { $0.slug == product.slug }

      SectionScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s7) {
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
        .padding(.top, Tokens.Space.s5)
      }
      .refreshable { await store.refresh() }
    } else {
      // The catalogue published no app in that role. Say so rather than draw an
      // empty screen — which is precisely the failure a `default:` case caused
      // on the expertise route.
      FailureView(failure: PhaseFailure(.nothingAvailable), retry: { store.load() })
    }
  }
}
