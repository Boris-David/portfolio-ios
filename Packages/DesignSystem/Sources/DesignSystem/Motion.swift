import SwiftUI

/// Le mouvement, avec **les mêmes courbes que le site**.
///
/// `Tokens.Ease` porte des courbes de Bézier cubiques, dans la forme qu'attendent
/// CSS et `Animation.timingCurve`. Les deux plateformes partagent donc la même
/// sensation — une carte qui se déplie a le même élan dans le navigateur et sur
/// le téléphone.
public enum Motion {
  /// L'arrivée d'un élément : rapide au départ, long à s'arrêter.
  public static let entrance = animation(Tokens.Ease.out, duration: Tokens.Duration.entrance)
  /// Le dépliage d'une carte — la plus longue, parce qu'on la regarde.
  public static let disclosure = animation(Tokens.Ease.soft, duration: Tokens.Duration.disclosure)
  /// Un aller-retour : une bascule, un changement d'état.
  public static let toggle = animation(Tokens.Ease.io, duration: Tokens.Duration.toggle)
  /// Un rebond mesuré, pour ce qui doit attirer l'œil une fois.
  public static let pop = animation(Tokens.Ease.back, duration: Tokens.Duration.pop)

  public static func animation(_ curve: Tokens.Curve, duration: Double) -> Animation {
    .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2, duration: duration)
  }
}

public extension View {
  /// Anime, **sauf** si la personne a demandé moins de mouvement.
  ///
  /// `prefers-reduced-motion` ne s'atténue pas, il se **supprime** : réduire de
  /// moitié une animation qui donne la nausée donne toujours la nausée. Le
  /// changement d'état reste instantané, et rien ne disparaît.
  func motion(_ animation: Animation, value: some Equatable, reduced: Bool) -> some View {
    self.animation(reduced ? nil : animation, value: value)
  }
}

/// Lit la préférence système de mouvement réduit.
///
/// Encapsulé dans un type plutôt que lu à la main dans chaque vue : une
/// préférence d'accessibilité qu'on doit penser à consulter est une préférence
/// qu'on oubliera quelque part.
@propertyWrapper
public struct ReducedMotion: DynamicProperty {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init() {}

  public var wrappedValue: Bool { reduceMotion }
}
