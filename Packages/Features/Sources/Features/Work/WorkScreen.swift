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
          .padding(.horizontal, Tokens.Space.s5)
        }

        VStack(spacing: Tokens.Space.s4) {
          ForEach(portfolio.caseStudies) { study in
            CaseStudyCard(study: study)
          }
        }
        .padding(.horizontal, Tokens.Space.s5)

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
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }

}

struct AppCell: View {
  let app: ProductionApp
  @Environment(\.openURL) private var openURL
  @Environment(ToastCenter.self) private var toasts
  @Localized(.interface) private var text

  var body: some View {
    Button {
      if let url = URL(string: app.appStoreURL) { openURL(url) }
    } label: {
      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        AppIconView(slug: app.slug)
        Text(app.name)
          .font(Typography.bodyStrong)
          .foregroundStyle(Color.ink)
          .lineLimit(1)
        Text(app.territory)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s3)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .fill(Color.paper2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular)
      )
    }
    .buttonStyle(.pressableCard)
    // Secondary actions, out of the way until asked for.
    //
    // A long press on a card is the iOS idiom for "what else can I do with
    // this". Putting a share button on thirty-three cards would have doubled the
    // grid's visual weight for something almost nobody wants — and the one
    // person who does already knows where to look.
    .contextMenu {
      if let url = URL(string: app.appStoreURL) {
        ShareLink(item: url) {
          Label(text(InterfaceText.share), icon: .share)
        }
        Button {
          UIPasteboard.general.url = url
          toasts.show(text(InterfaceText.linkCopied), kind: .succeeded, icon: .succeeded)
        } label: {
          Label(text(InterfaceText.copyLink), icon: .link)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(app.name), \(app.territory)")
    .accessibilityHint(text(InterfaceText.openInAppStore))
    .decision(WorkDecisions.contextMenu)
  }
}

/// An app's icon, named by its **public slug**.
///
/// Never by an internal network identifier: those do not leave the building, and
/// an image path is public content just as much as a sentence is.
struct AppIconView: View {
  let slug: String

  var body: some View {
    ContentImage(slug, kind: .appIcon)
      .frame(width: Tokens.Layout.appIconSide, height: Tokens.Layout.appIconSide)
      .clipShape(RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)
  }
}
