import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The home screen: who he is, in three seconds.
///
/// The reading order is decided, not inherited — availability, name, role, then
/// the figures, then the call to action. A recruiter **skims**; what matters has
/// to be findable without scrolling.
public struct ProfileScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(title: text(InterfaceText.tabProfile)) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot)
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────

  private func content(_ snapshot: PortfolioSnapshot) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        FreshnessBanner(snapshot: snapshot, language: store.language)
        IdentityBlock(profile: snapshot.portfolio.profile)
        MetricsBlock(metrics: snapshot.portfolio.metrics)
        ExpertiseBlock(
          section: snapshot.portfolio.section("depth"),
          topics: snapshot.portfolio.expertise
        )
        ContactBlock(contact: snapshot.portfolio.profile.contact)
      }
      .padding(.bottom, Tokens.Space.s8)
      .readableWidth()
    }
    // Pull to refresh: the expected gesture, and it genuinely waits for the
    // end — an indicator that vanishes before the content arrives reads as the
    // gesture having done nothing.
    .refreshable { await store.refresh() }
    .decision(ProfileDecisions.scrollView)
  }
}
