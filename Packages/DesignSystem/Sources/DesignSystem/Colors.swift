import SwiftUI

/// Les couleurs du portfolio, en version SwiftUI.
///
/// Chaque couleur est **dynamique** : elle porte sa valeur claire et sa valeur
/// sombre, et le système choisit. C'est ce qui rend impossible le défaut le plus
/// courant — une teinte définie pour un seul thème, illisible sur l'autre — sans
/// avoir à y penser à chaque usage.
///
/// Elles sont construites depuis `Tokens`, généré à partir de
/// `design/tokens.json`. Le site et l'application affichent donc **exactement**
/// la même palette : pas « la même à peu près », la même valeur hexadécimale.
public extension Color {
  /// Le fond principal — le papier chaud.
  static let paper = Color(Tokens.Color.paper)
  /// Un fond légèrement creusé, pour les surfaces posées dessus.
  static let paper2 = Color(Tokens.Color.paper2)
  /// Le creux le plus marqué — puces, champs, zones inertes.
  static let paper3 = Color(Tokens.Color.paper3)

  /// Le trait fin qui sépare sans cloisonner.
  static let line = Color(Tokens.Color.line)
  /// Un trait plus affirmé, réservé aux séparations qui portent du sens.
  static let line2 = Color(Tokens.Color.line2)

  /// L'encre — le texte principal.
  static let ink = Color(Tokens.Color.ink)
  /// L'encre secondaire, pour ce qui accompagne.
  static let ink2 = Color(Tokens.Color.ink2)
  /// L'encre tertiaire : légendes, métadonnées, ce qui se lit après.
  static let ink3 = Color(Tokens.Color.ink3)

  /// L'accent — un indigo, et un seul, pour ce sur quoi on agit.
  static let accent = Color(Tokens.Color.accent)
  /// L'accent enfoncé, pour l'état pressé.
  static let accentDeep = Color(Tokens.Color.accentD)
  /// L'accent lavé, pour les fonds teintés.
  static let accentWash = Color(Tokens.Color.accentW)
  /// Ce qui s'écrit **sur** l'accent.
  static let onAccent = Color(Tokens.Color.onAccent)

  /// Le vert des états réussis. Séparé de l'accent : une couleur sémantique et
  /// une couleur de marque ne se confondent pas, sinon « réussi » et
  /// « cliquable » se ressemblent.
  static let ok = Color(Tokens.Color.ok)

  init(_ palette: Tokens.Palette) {
    self = Color(uiColor: UIColor { traits in
      UIColor(traits.userInterfaceStyle == .dark ? palette.dark : palette.light)
    })
  }
}

private extension UIColor {
  convenience init(_ components: Tokens.Components) {
    self.init(
      red: components.red,
      green: components.green,
      blue: components.blue,
      alpha: 1
    )
  }
}
