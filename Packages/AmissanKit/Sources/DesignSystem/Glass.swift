import SwiftUI

/// Liquid Glass sur iOS 26, et un repli assumé sur iOS 18.
///
/// ## Pourquoi une couche, plutôt que des `if #available` disséminés
///
/// L'application vise **iOS 18 et plus**, et se compile avec le SDK d'iOS 26.
/// Les deux mondes coexistent donc dans le même binaire. Trois façons de vivre
/// avec :
///
/// 1. *ne cibler qu'iOS 26* — on perd les appareils qui ne sont pas passés à la
///    version majeure, c'est-à-dire une part qui se compte en dizaines de
///    pour cent les premiers mois ;
/// 2. *semer des `if #available(iOS 26, *)` dans les vues* — ça marche, et au
///    bout de trente écrans plus personne ne sait ce que voit un utilisateur
///    d'iOS 18. Le repli n'est testé nulle part parce qu'il n'est nommé nulle
///    part ;
/// 3. **nommer l'intention, et faire décider la couche** — `.navigationGlass()`
///    dit *« ceci est une surface de navigation »*. Comment ça se rend est
///    décidé ici, en un seul endroit, et les deux rendus sont visibles côte à
///    côte dans les aperçus.
///
/// C'est la troisième. Le coût d'un SDK qui évolue se paie une fois, dans ce
/// fichier, au lieu d'être réparti partout.
///
/// ## Ce sur quoi le glass ne s'applique **pas**
///
/// Liquid Glass est un matériau de la couche **navigation** : barres, boutons,
/// accessoires. Le poser sur du contenu — une liste, un paragraphe, une image —
/// dégrade le contraste du texte et brouille la hiérarchie : tout se met à
/// flotter, donc plus rien ne ressort. La règle est tenue par la nomenclature :
/// il n'existe pas de `contentGlass()`.
public extension View {
  /// Une surface de navigation : barre flottante, groupe de contrôles, bouton
  /// posé au-dessus du contenu.
  ///
  /// - Parameters:
  ///   - shape: la forme découpée. Une capsule par défaut, parce que c'est ce
  ///     que le système emploie pour ses propres contrôles flottants.
  ///   - tint: une teinte, pour signaler un état actif. `nil` la plupart du
  ///     temps — un matériau teinté partout redevient une couleur.
  ///   - interactive: le verre réagit au toucher. Réservé à ce qui est
  ///     réellement tactile, sinon la surface promet une action qui n'existe pas.
  @ViewBuilder
  func navigationGlass(
    // `InsettableShape` et non `Shape` : c'est le protocole qui apporte
    // `strokeBorder`, lequel trace **vers l'intérieur**. Un `stroke` ordinaire
    // déborde d'une demi-épaisseur et rogne le contenu voisin.
    in shape: some InsettableShape = Capsule(),
    tint: Color? = nil,
    interactive: Bool = false
  ) -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(
        Glass.regular.tint(tint).interactive(interactive),
        in: shape
      )
    } else {
      // Le repli n'est pas « la même chose en moins bien » : c'est le matériau
      // qu'iOS 18 emploie lui-même pour ses barres. Un utilisateur d'iOS 18 voit
      // une application d'iOS 18, pas une imitation ratée d'iOS 26.
      self
        .background {
          shape
            .fill(.ultraThinMaterial)
            // La teinte se pose **au-dessus** du matériau, pas en dessous :
            // en dessous, le flou l'aurait délavée jusqu'à l'invisible.
            .overlay(shape.fill(tint?.opacity(0.14) ?? .clear))
            .overlay(shape.strokeBorder(Color.line.opacity(0.6), lineWidth: 0.5))
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
  }

  /// La barre d'onglets se réduit quand on descend dans le contenu.
  ///
  /// iOS 26 seulement : sur iOS 18 la barre reste, ce qui est son comportement
  /// normal et n'a rien d'un défaut.
  @ViewBuilder
  func minimizingTabBarOnScroll() -> some View {
    if #available(iOS 26.0, *) {
      self.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      self
    }
  }
}

/// Regroupe plusieurs surfaces de verre pour qu'elles se fondent entre elles.
///
/// Sans conteneur, deux boutons de verre côte à côte sont deux verres
/// **empilés** : le fond est échantillonné deux fois et le rendu s'assombrit à
/// leur intersection. Le conteneur les fusionne en une seule couche.
///
/// Sur iOS 18 il ne fait rien de plus qu'un `HStack` — et c'est exactement ce
/// qu'on veut : la structure du code ne change pas d'une version à l'autre.
public struct GlassGroup<Content: View>: View {
  private let spacing: CGFloat
  private let content: Content

  public init(spacing: CGFloat = Tokens.Space.s2, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: spacing) { content }
    } else {
      content
    }
  }
}

/// Le style des boutons flottants — verre sur iOS 26, bordé sur iOS 18.
public struct AdaptiveGlassButtonStyle: ButtonStyle {
  private let prominent: Bool

  public init(prominent: Bool = false) {
    self.prominent = prominent
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.bodyStrong)
      .foregroundStyle(prominent ? Color.onAccent : Color.ink)
      .padding(.horizontal, Tokens.Space.s4)
      .frame(minHeight: Tokens.Accessibility.minimumTouchTarget)
      .background { surface }
      // Le retour au toucher est le même dans les deux mondes : c'est une
      // information, pas une décoration, et elle ne dépend pas du matériau.
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(Motion.toggle, value: configuration.isPressed)
  }

  /// ⚠️ Un bouton **principal** ne se rend pas pareil dans les deux mondes, et
  /// ce n'est pas un détail d'esthétique.
  ///
  /// Sur iOS 26, `Glass.tint(_:)` produit une surface dont le système garantit
  /// la lisibilité du contenu. Sur iOS 18, poser la même teinte à faible
  /// opacité sur un matériau translucide donne, en thème clair, **du blanc sur
  /// du pâle** — mesuré à l'écran, illisible.
  ///
  /// Le repli est donc un aplat d'accent. Ce n'est pas « du verre en moins
  /// bien » : c'est ce qu'iOS 18 emploie lui-même pour une action principale,
  /// et le contraste y est celui qu'on a choisi dans les tokens.
  @ViewBuilder
  private var surface: some View {
    if prominent {
      if #available(iOS 26.0, *) {
        Capsule().fill(Color.clear).navigationGlass(
          in: Capsule(),
          tint: Color.accent,
          interactive: true
        )
      } else {
        Capsule().fill(Color.accent)
      }
    } else {
      Capsule().fill(Color.clear).navigationGlass(in: Capsule(), interactive: true)
    }
  }
}

public extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
  /// Un bouton flottant secondaire.
  static var adaptiveGlass: AdaptiveGlassButtonStyle { AdaptiveGlassButtonStyle() }
  /// L'action principale d'un écran — une seule par écran.
  static var adaptiveGlassProminent: AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(prominent: true)
  }
}

/// Ce que l'appareil sait faire, rendu **lisible** — et affichable.
///
/// Les Coulisses s'en servent pour dire à qui regarde : *« vous voyez le rendu
/// iOS 26 »* ou *« vous voyez le repli iOS 18 »*. Un compromis de compatibilité
/// qu'on ne peut pas constater à l'écran est un compromis qu'on doit croire sur
/// parole.
public enum PlatformCapabilities {
  public static var supportsLiquidGlass: Bool {
    if #available(iOS 26.0, *) { true } else { false }
  }

  public static var summary: String {
    supportsLiquidGlass
      ? "iOS 26 — Liquid Glass natif"
      : "iOS 18 — repli en matériau système"
  }
}
