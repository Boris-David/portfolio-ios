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
  public enum Level {
    /// Laid on the paper, separated by a hairline. The default.
    case flat
    /// Slightly recessed — a group within a group.
    case recessed
    /// Lifted, with a shadow. **One per screen at most**: it is what the eye
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
      .shadow(
        color: level == .raised ? .black.opacity(Tokens.Elevation.raised.opacity) : .clear,
        radius: level == .raised ? Tokens.Elevation.raised.radius : 0,
        y: level == .raised ? Tokens.Elevation.raised.y : 0
      )
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
