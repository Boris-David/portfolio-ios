import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// What he built himself, end to end — as a list you can take in at a glance.
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
/// ## Why a list, and why the detail is presented
///
/// It rendered every product in full, one after the other: KCalories' four
/// screenshots and its whole story, and only then the next app. The author's
/// reading was that the tab had stopped answering its own question — *"you have
/// to be able to see all the apps at a glance"*. A list answers it in one
/// screen; the depth is one tap away.
///
/// That tap **presents** rather than pushes. A product detail is a thing you
/// look at and come back from, which is what a modal means; pushing would put a
/// full case study under a tab bar and make the way back a back button. The
/// same reasoning already governs a case study opened from deep inside a stack.
///
/// ## Two tiers, kept apart
///
/// Products first, then the open projects — a component and an interview
/// exercise, which moved here from the journey. They belong in this tab, which
/// answers "what has he built himself"; they do not belong at the same level as
/// something published, and running them together would let an exercise stand
/// next to an App Store product as though it were the same claim.
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
    // Named by the content and never by a slug written here. The day a third
    // one ships, this screen shows it without a line changing.
    let products = portfolio.apps.ownedEndToEnd
    let openProjects = portfolio.background.openProjects

    if products.isEmpty, openProjects.isEmpty {
      // The catalogue published nothing in that role. Say so rather than draw an
      // empty screen — which is precisely the failure a `default:` case caused
      // on the expertise route.
      FailureView(failure: PhaseFailure(.nothingAvailable), retry: { store.load() })
    } else {
      List {
        Section {
          ForEach(products) { product in
            ProductRow(product: product, study: study(for: product, in: portfolio))
          }
        }

        if !openProjects.isEmpty {
          Section {
            ForEach(openProjects) { OpenProjectRow(project: $0) }
          } header: {
            Text(text(InterfaceText.openProjects)).eyebrowStyle()
          }
        }
      }
      .listStyle(.insetGrouped)
      // The list draws its own grouped background, a system grey the rest of
      // the app does not use. Hidden, so the paper shows through.
      .scrollContentBackground(.hidden)
      // ⚠️ A `List` on iPad runs the full width of the window — a line of text
      // measured **1 300 pt** there before this was applied to the journey.
      .readableWidth()
      .refreshable { await store.refresh() }
    }
  }

  private func study(for product: ProductionApp, in portfolio: Portfolio) -> CaseStudy? {
    portfolio.caseStudies.first { $0.slug == product.slug }
  }
}
