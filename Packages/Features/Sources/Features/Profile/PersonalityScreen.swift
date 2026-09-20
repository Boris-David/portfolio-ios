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
/// from, and closing it costs a swipe rather than a back button. Opening at
/// `.medium` also means the first thing they see is the whole of the first
/// paragraph — the roles, which are the part that says something — instead of a
/// title and a scroll bar.
///
/// ## Why the signature is at the bottom
///
/// Because that is where a signature goes. Put at the top it would have taken
/// 44 pt of the one screenful this sheet gets at its opening detent, above the
/// sentence it is meant to sign — the roles, which are the part that says
/// something. At the end it closes the statement instead of announcing it.
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
        ForEach(Array(personality.summary.enumerated()), id: \.offset) { _, paragraph in
          RichTextView(paragraph)
        }

        if !personality.interests.isEmpty {
          VStack(alignment: .leading, spacing: Tokens.Space.s3) {
            Text(text(InterfaceText.interests)).eyebrowStyle()
            WrappingRow {
              ForEach(personality.interests, id: \.self) { Chip($0) }
            }
          }
        }

        LottieAnimation(LottieCatalogue.signature)
          .frame(height: Tokens.Layout.signatureHeight)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .accessibilityHidden(true)
          .decision(ProfileDecisions.personality)
          .padding(.top, Tokens.Space.s3)
      }
      .padding(.top, Tokens.Space.s4)
    }
  }
}
