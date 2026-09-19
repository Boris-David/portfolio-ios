import DesignSystem
import SwiftUI

/// A content surface — the design system's card.
///
/// ## Not everything is a card
///
/// Border, fill, radius and shadow each say "separate object". Spending them
/// everywhere flattens the hierarchy: when everything is a card, nothing stands
/// out. So the type carries a **level**, and each level has a reason to exist
/// rather than a look.
public struct Surface<Content: View>: View {
  /// ## Why each level has its own shadow, and one has none
  ///
  /// A card sitting flat on the paper reads as printing; the same card lifted a
  /// few points reads as an **object** — which is what a card is meant to be,
  /// and what the author asked for after using the app: shadow around the
  /// cards, for relief.
  ///
  /// The temptation is to give all three the same shadow, and that is exactly
  /// the look this repository refuses: identical cards, one radius and one
  /// shadow everywhere, flattens the hierarchy — when everything is lifted,
  /// nothing is. So the shadow is a **scale**, and it says the same thing the
  /// level already said:
  ///
  /// | Level | Shadow | What it means |
  /// |---|---|---|
  /// | `recessed` | none | it is *in* the page, not on it |
  /// | `flat` | `Elevation.resting` | an object on the paper |
  /// | `raised` | `Elevation.raised` | the thing the eye reaches first |
  public enum Level {
    /// Laid on the paper, lifted a few points. The default.
    case flat
    /// Slightly recessed — a group within a group. **No shadow**: it is set
    /// into the page, and a recess that casts a shadow is a contradiction.
    case recessed
    /// Lifted, and clearly. **One per screen at most**: it is what the eye
    /// reaches first, and two things cannot both be first.
    case raised
  }

  private let level: Level
  private let padding: CGFloat
  private let content: Content

  public init(
    _ level: Level = .flat,
    padding: CGFloat = Tokens.Space.s5,
    @ViewBuilder content: () -> Content
  ) {
    self.level = level
    self.padding = padding
    self.content = content()
  }

  public var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .strokeBorder(Color.line, lineWidth: level == .recessed ? 0 : Tokens.Stroke.regular)
      )
      .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
      // ⚠️ The shadow goes **after** the clip, never inside it: a shadow drawn
      // before `clipShape` is clipped away by it, which compiles, warns about
      // nothing, and renders a card with no shadow at all.
      .shadow(
        color: .black.opacity(elevation?.opacity ?? 0),
        radius: elevation?.radius ?? 0,
        y: elevation?.y ?? 0
      )
  }

  /// `nil` for the level that is set into the page rather than laid on it.
  private var elevation: Tokens.Shadow? {
    switch level {
    case .flat: Tokens.Elevation.resting
    case .recessed: nil
    case .raised: Tokens.Elevation.raised
    }
  }

  private var background: Color {
    switch level {
    case .flat: .paper
    case .recessed: .paper2
    case .raised: .paper
    }
  }
}

/// The rule that opens a section — a landmark, not a decoration.
public struct SectionHeader: View {
  private let eyebrow: String
  private let title: String
  private let intro: String?

  public init(eyebrow: String, title: String, intro: String? = nil) {
    self.eyebrow = eyebrow
    self.title = title
    self.intro = intro
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(eyebrow).eyebrowStyle()
      Text(title)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        // A title that breaks over two lines must balance them, or the second
        // carries a single word and the block looks broken.
        .fixedSize(horizontal: false, vertical: true)
      if let intro {
        Text(intro)
          .font(Typography.body)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, Tokens.Space.s1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // The title and its rule are **one** element for VoiceOver: announcing them
    // separately would read "zero two" and then, later, the title.
    .accessibilityElement(children: .combine)
  }
}
