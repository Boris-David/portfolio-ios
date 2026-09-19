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
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        if let section = portfolio.section("case-studies") {
          SectionHeader(
            eyebrow: section.eyebrow,
            title: section.title,
            intro: section.intro?.plain
          )
        }

        VStack(spacing: Tokens.Space.s4) {
          ForEach(portfolio.caseStudies) { study in
            CaseStudyCard(study: study)
          }
        }

        AppsBlock(
          section: portfolio.section("apps"),
          catalogue: portfolio.apps
        )
      }
      .padding(.top, Tokens.Space.s4)
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

          WrappingRow {
            ForEach(study.tags.prefix(6), id: \.self) { tag in
              Chip(tag)
            }
            if study.tags.count > 6 {
              Chip("+\(study.tags.count - 6)", emphasis: .accented)
            }
          }

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
      if let section {
        SectionHeader(
          eyebrow: section.eyebrow,
          title: section.title,
          intro: section.intro?.plain
        )
      }

      LazyVGrid(columns: columns, spacing: Tokens.Space.s3) {
        ForEach(catalogue.ticketing) { app in
          AppCell(app: app)
        }
      }
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
