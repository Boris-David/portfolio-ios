import SwiftUI

/// Une surface de contenu — la carte du design system.
///
/// ## Tout n'est pas une carte
///
/// Bordure, remplissage, rayon et ombre disent chacun « objet distinct ». Les
/// dépenser partout aplatit la hiérarchie : quand tout est une carte, plus rien
/// ne ressort. Le type porte donc un **niveau**, et chaque niveau a une raison
/// d'exister plutôt qu'une esthétique.
public struct Surface<Content: View>: View {
  public enum Level {
    /// Posée sur le papier, séparée par un simple trait. Le défaut.
    case flat
    /// Légèrement creusée — un groupe dans un groupe.
    case recessed
    /// Détachée, avec une ombre. **Une par écran, au plus** : c'est ce qui
    /// attire l'œil en premier, et deux choses en premier n'existent pas.
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

/// Le liseré qui ouvre une section — un repère, pas une décoration.
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
        // Un titre qui casse sur deux lignes doit les équilibrer, sinon la
        // seconde porte un mot seul et le bloc a l'air cassé.
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
    // Le titre et son liseré forment **un** élément pour VoiceOver : les
    // annoncer séparément ferait lire « zéro deux » puis, plus tard, le titre.
    .accessibilityElement(children: .combine)
  }
}
