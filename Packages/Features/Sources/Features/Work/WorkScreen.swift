import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import UIKit
import ViewKit

/// The projects, told the way an engineer delivers: the problem, the decision,
/// the result.
public struct WorkScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(.work) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot.portfolio)
      }
    }
  }

  private func content(_ portfolio: Portfolio) -> some View {
    SectionScrollView {
      // ⚠️ No section header above the cards.
      //
      // There was one: an eyebrow, a serif title and a three-line standfirst
      // explaining how to read the page — *"the problem, the decisions I took,
      // and what they produced"* — set directly under the navigation bar's own
      // large title. Three titles stacked, of which two say the same thing and
      // the third is meta-commentary about the page rather than content on it.
      //
      // Two cards that each name a project need no instructions.
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        VStack(spacing: Tokens.Space.s4) {
          ForEach(portfolio.caseStudies) { study in
            CaseStudyCard(study: study)
          }
        }

        AppsBlock(
          section: portfolio.section("apps"),
          catalogue: portfolio.apps
        )

        // The way into how **this** app is built. It was a tab; it is a reading,
        // and it belongs one tap from the projects that raise the question
        // rather than in the bar beside them.
        ReadingLinkRow(
          route: .engineering,
          title: text(InterfaceText.engineeringTitle),
          summary: text(InterfaceText.engineeringIntro)
        )
      }
      .padding(.top, Tokens.Space.s5)
    }
    .refreshable { await store.refresh() }
  }
}

/// A case study's card: collapsed it gives the scale, expanded it gives the
/// detail.
struct CaseStudyCard: View {
  let study: CaseStudy

  @Environment(Router.self) private var router
  @Localized(.interface) private var text

  var body: some View {
    Button {
      router.push(.caseStudy(slug: study.slug))
    } label: {
      Surface {
        VStack(alignment: .leading, spacing: Tokens.Space.s3) {
          Text(study.subtitle).eyebrowStyle()
          Text(study.title)
            .font(Typography.heading)
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

          if let intro = study.intro {
            Text(intro.plain)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .lineLimit(3)
              .multilineTextAlignment(.leading)
          }

          // ⚠️ The way in comes **before** the technologies, and this is the
          // whole point of the swap.
          //
          // Six chips took a third of the card's height and pushed the only
          // actionable line under the fold of the card itself — so the card
          // that opens a case study looked like a card that lists frameworks.
          // `Chip.swift` says it in its own doc: a list of technologies is not
          // an argument.
          //
          // Three chips, not six: the rest are in the study, where they are
          // attached to the thing they were used for.
          HStack(spacing: Tokens.Space.s2) {
            Text(study.hasNamedChapters
              ? text(InterfaceText.chapterCount, count: study.chapters.count)
              : text(InterfaceText.readStudy))
              .font(Typography.caption)
              .foregroundStyle(Color.accent)
            Image(systemName: "arrow.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(Color.accent)
          }
          .padding(.top, Tokens.Space.s1)

          WrappingRow {
            ForEach(study.tags.prefix(3), id: \.self) { tag in
              Chip(tag)
            }
            if study.tags.count > 3 {
              Chip("+\(study.tags.count - 3)", emphasis: .accented)
            }
          }
        }
      }
    }
    .buttonStyle(.pressableCard)
    // The card is the thing the detail screen grows out of. It took a namespace
    // as a parameter and never used it, so the push matched nothing and fell
    // back to a slide — silently, because a zoom with one half is not an error.
    // The namespace now comes from the stack that holds both halves.
    .zoomSource(study.slug)
    .reveal()
  }
}

/// The grid of production apps.
struct AppsBlock: View {
  let section: Portfolio.Section?
  let catalogue: AppCatalogue
  @Localized(.interface) private var text

  private let columns = [GridItem(.adaptive(minimum: 150), spacing: Tokens.Space.s3)]

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      // The eyebrow, not the full header. The section's title — the one that
      // spells out the count of apps and territories — opens the profile tab,
      // and the editorial rule on that figure is explicit: it carries once,
      // where it installs the scale. Said twice it becomes a tic, and takes
      // the place of a fact that has not been said yet. Thirty-three cells say
      // it here.
      if let section {
        Text(section.eyebrow).eyebrowStyle()
      }

      LazyVGrid(columns: columns, spacing: Tokens.Space.s3) {
        ForEach(catalogue.ticketing) { app in
          AppCell(app: app)
        }
      }
      .decision(WorkDecisions.grid)
      .decision(WorkDecisions.grid)

      if let note = section?.note {
        Text(note.plain)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
          .fixedSize(horizontal: false, vertical: true)
      }

      Text(text(InterfaceText.verifiedOn, catalogue.verifiedOn))
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
    }
    .reveal()
  }

}
