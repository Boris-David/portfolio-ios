import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// A subject, dug into.

/// ## Why this screen had to exist
///
/// The profile lists three topics and says the author can be questioned on each
/// for an hour. On its own that is a claim like any other, and a reader has no
/// way to weigh it. This is what makes it checkable: the reasoning, what it
/// rules out, and a pointer to where it was actually done.
///
/// Until 2026-09-18 touching a topic opened a **black screen**. The route
/// existed, the API served the content, and no screen had ever been written —
/// the resolver's `default:` returned an `EmptyView`, in silence. That
/// `default:` is gone, so the compiler now refuses a route nothing renders.
public struct DeepDiveScreen: View {
  private let topic: ExpertiseTopic
  private let dive: DeepDive?

  @Localized(.interface) private var text

  public init(topic: ExpertiseTopic, dive: DeepDive?) {
    self.topic = topic
    self.dive = dive
  }

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s6) {
        header

        if let dive {
          RichTextView(dive.lede, font: Typography.body)
            .fixedSize(horizontal: false, vertical: true)

          ForEach(dive.sections) { section in
            self.section(section)
          }

          if let evidence = dive.evidence {
            self.evidence(evidence)
          }
        }
      }
    }
    .background(Color.paper)
    .navigationTitle(topic.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  // -- The parts ----------------------------------------------------------

  /// ⚠️ No title in the page. The bar already carries it, in full — these
  /// titles are short enough to fit an inline bar — so printing it again forty
  /// points below spends the first screenful on a word the reader has just
  /// read.
  ///
  /// That is the opposite call from the case study, and the difference is the
  /// length: a title the bar has to truncate stays in the content, which can
  /// wrap. See `.claude/rules/interface.md`.
  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(text(InterfaceText.depthEyebrow)).eyebrowStyle()
      RichTextView(topic.body, font: Typography.body)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, Tokens.Space.s4)
  }

  private func section(_ section: DeepDive.Section) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(section.heading)
        .font(Typography.heading)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)

      ForEach(Array(section.blocks.prose.enumerated()), id: \.offset) { _, paragraph in
        RichTextView(paragraph, font: Typography.body)
          .fixedSize(horizontal: false, vertical: true)
      }

      let tags = section.blocks.tags
      if !tags.isEmpty {
        WrappingRow {
          ForEach(tags, id: \.self) { Chip($0) }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Where the reasoning was actually applied.
  ///
  /// A link and not a copy: the case study already carries that chapter once,
  /// and a second version of it here would be a second version to keep true.
  private func evidence(_ evidence: DeepDive.Evidence) -> some View {
    NavigationLink(value: Route.caseStudy(slug: evidence.caseStudy)) {
      Surface {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
          Image(.work)
            .foregroundStyle(Color.accent)
          VStack(alignment: .leading, spacing: 2) {
            Text(text(InterfaceText.provenTitle)).eyebrowStyle()
            Text(text(InterfaceText.provenLink))
              .font(Typography.bodyStrong)
              .foregroundStyle(Color.ink)
              .fixedSize(horizontal: false, vertical: true)
          }
          Spacer(minLength: Tokens.Space.s3)
          Image(systemName: "chevron.right")
            .font(.footnote)
            .foregroundStyle(Color.ink3)
        }
      }
    }
    .buttonStyle(.pressableCard)
  }
}
