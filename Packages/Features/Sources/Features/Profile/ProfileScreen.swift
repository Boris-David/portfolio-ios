import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The home screen: who he is, at what scale, and what he has shipped — in
/// three seconds.
///
/// ## The reading order, and why it is this one
///
/// A recruiter **skims**. Every block below earns its position by what it gives
/// somebody who reads no further than it:
///
/// 1. **who, and is he reachable** — the name, the role, the remote line;
/// 2. **at what scale** — `~5 M`, `6 ans`, `> 99,8 %`, in one row rather than
///    383 pt of stacked cards;
/// 3. **what he has shipped, alone** — the KCalories screenshot the API has
///    always published and nothing ever drew;
/// 4. **and at what volume** — the shelf of production apps, which used to be
///    1 050 pt down the second tab;
/// 5. **where he goes deep** — the three essays;
/// 6. **how to reach him** — the action, once, after the argument rather than
///    before it.
///
/// The provenance of the content comes last, which is where a footnote goes. It
/// opened the screen before: the first sentence of the application was an
/// apology about the age of a cache.
public struct ProfileScreen: View {
  @Environment(PortfolioStore.self) private var store

  public init() {}

  public var body: some View {
    SectionShell(.profile, opening: .content) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot)
      }
    }
  }

  private func content(_ snapshot: PortfolioSnapshot) -> some View {
    let portfolio = snapshot.portfolio

    return SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        IdentityBlock(profile: portfolio.profile)
        MetricsBlock(metrics: portfolio.metrics)
        ShowcaseBlock(showcase: portfolio.profile.showcase)
        ProductionAppsBlock(
          section: portfolio.section("apps"),
          catalogue: portfolio.apps
        )
        ExpertiseBlock(
          section: portfolio.section("depth"),
          topics: portfolio.expertise
        )
        ContactBlock(contact: portfolio.profile.contact)
        FreshnessBanner(snapshot: snapshot, language: store.language)
      }
    }
    // Pull to refresh: the expected gesture, and it genuinely waits for the
    // end — an indicator that vanishes before the content arrives reads as the
    // gesture having done nothing.
    .refreshable { await store.refresh() }
    .decision(ProfileDecisions.scrollView)
  }
}
