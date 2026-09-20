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
  @Environment(\.present) private var present

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

        // The way into the one page written in the first person. It sits at the
        // end because that is the order a reader wants it in: what he has done,
        // then who he is. Presented and not pushed — an aside, not a chapter.
        Button { present(.personality) } label: {
          HStack(spacing: Tokens.Space.s2) {
            Text(text(InterfaceText.personalityLink))
            Image(systemName: "arrow.up.right")
              .font(.system(size: Tokens.Icon.caption, weight: .semibold))
          }
          .font(Typography.secondary)
          .foregroundStyle(Color.accent)
        }
        .buttonStyle(.plain)
        .padding(.top, Tokens.Space.s3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, Tokens.Space.s5)
    }
    .background(Color.paper)
    .navigationTitle(text(InterfaceText.aboutTitle))
    .navigationBarTitleDisplayMode(.inline)
  }

  /// ⚠️ Two of these were drawing **somebody else's glyph**: an envelope for
  /// "open to opportunities" and a person for "Alpes-Maritimes", because the
  /// icon set had no meaning for either and the nearest case was taken.
  ///
  /// That is exactly what `Icon` exists to prevent — it names a meaning, so a
  /// missing meaning shows up as a borrowed one rather than as a compile error.
  /// The set gained the two it was short of, and `IconTests` checks every
  /// symbol resolves.
  ///
  /// ⚠️ There is no separate télétravail row. `availability` says what he is
  /// open to, remote included, since 2026-09-20 — and the short form the résumé
  /// puts in its facts line would only repeat it here, one row apart.
  private var facts: [(icon: Icon, text: String)] {
    [
      (.location, profile.location),
      (.availability, profile.availability),
      (.language, profile.languages),
    ]
  }
}
