import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The long introduction, one tap from the opening.
///
/// ## Why this is a screen and not the top of the home screen
///
/// It used to be three paragraphs under the name, and it pushed everything that
/// gives scale — the figures, the depth topics — below the fold. A recruiter
/// **skims**: the first screen has to answer "who is this, and is he available"
/// without scrolling, and the prose is what they read once they have decided to.
///
/// Pushed rather than presented: it is a continuation of the profile, and the
/// back button should say so.
public struct AboutScreen: View {
  private let profile: Profile

  @Localized(.interface) private var text

  public init(profile: Profile) {
    self.profile = profile
  }

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        ForEach(Array(profile.summary.enumerated()), id: \.offset) { _, paragraph in
          RichTextView(paragraph)
        }

        Divider().padding(.vertical, Tokens.Space.s2)

        ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
          HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
            Image(fact.icon)
              .font(.system(size: Tokens.Icon.caption))
              .foregroundStyle(Color.accent)
              .frame(width: Tokens.Icon.inline)
            Text(fact.text)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .fixedSize(horizontal: false, vertical: true)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, Tokens.Space.s5)
    }
    .background(Color.paper)
    .navigationTitle(text(InterfaceText.aboutTitle))
    .navigationBarTitleDisplayMode(.inline)
  }

  private var facts: [(icon: Icon, text: String)] {
    [
      (.contact, profile.availability),
      (.profile, profile.location),
      (.language, profile.languages),
    ]
  }
}
