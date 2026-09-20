import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// Who he is when he is not writing code.
///
/// ## Why a sheet, and why it opens at a medium detent
///
/// It is an aside, not a chapter. The reader keeps a foot on the page they came
/// from, and closing it costs a swipe rather than a back button.
///
/// ## Why one line is set much larger than the rest
///
/// Because it is the line somebody repeats about him afterwards. *"Mister Good
/// Mood, voted for by the whole company"* was a sentence of running prose among
/// three others, and it disappeared into them — the author's reading of the
/// first version was *"just a pile of words put together"*.
///
/// The emphasis is **typographic and nothing else**: a large serif on the same
/// paper, no card, no rule, no tint. A distinction that needed a badge to be
/// noticed would be a distinction nobody gave him.
///
/// The detail under it is not decoration either: it carries the vote and the
/// year. Without them the title is somebody handing themselves a prize.
public struct PersonalityScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    NavigationStack {
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot.portfolio.profile.personality)
      }
      .navigationTitle(text(InterfaceText.personalityTitle))
      .navigationBarTitleDisplayMode(.inline)
    }
    // Medium first, large for whoever wants the whole of it. The grabber says
    // both are available without a label having to.
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func content(_ personality: Profile.Personality) -> some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s5) {
        highlight(personality.highlight)

        Divider()

        ForEach(Array(personality.summary.enumerated()), id: \.offset) { _, paragraph in
          RichTextView(paragraph)
        }

        if !personality.interests.isEmpty {
          VStack(alignment: .leading, spacing: Tokens.Space.s3) {
            Text(text(InterfaceText.interests)).eyebrowStyle()
            WrappingRow {
              ForEach(personality.interests) { interest in
                Chip(interest.label, systemImage: InterestGlyph.name(for: interest.id))
              }
            }
          }
          .padding(.top, Tokens.Space.s2)
        }
      }
      .padding(.vertical, Tokens.Space.s4)
    }
  }

  private func highlight(_ highlight: Profile.Personality.Highlight) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(highlight.title)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(highlight.detail)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink3)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
    .decision(ProfileDecisions.personality)
  }
}
