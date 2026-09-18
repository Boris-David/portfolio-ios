import SwiftUI

/// La typographie — **native**, et compatible Dynamic Type par construction.
///
/// ## Pourquoi pas les polices du site
///
/// Le site est composé en Fraunces et Instrument Sans. Les embarquer dans
/// l'application aurait coûté deux fichiers, un chargement, et surtout la
/// **compatibilité Dynamic Type** : une police personnalisée ne suit les tailles
/// système que si on la câble soi-même, et ce câblage est précisément ce qu'on
/// oublie de tester en accessibilité extra-large.
///
/// iOS fournit deux familles qui tiennent le même rôle, gratuitement :
///
/// | Rôle | Site | Application |
/// |---|---|---|
/// | Titres | Fraunces (serif à contraste) | **New York** — `design: .serif` |
/// | Texte | Instrument Sans | **SF Pro** — `design: .default` |
/// | Code | ui-monospace | **SF Mono** — `design: .monospaced` |
///
/// Le choix n'est pas un pis-aller : une application qui compose en New York
/// **ressemble à une application iOS**, là où une police web plaquée dessus a
/// toujours l'air d'une page web dans une coquille.
///
/// ## L'échelle
///
/// `design/tokens.json` porte déjà une échelle alignée sur Dynamic Type — base
/// 17, comme iOS. Les styles ci-dessous s'y rattachent donc un à un, et les
/// tailles en points ne servent qu'aux rares endroits où l'on doit calculer.
public enum Typography {
  /// Le nom affiché, la seule occurrence vraiment monumentale.
  public static let hero = Font.system(.largeTitle, design: .serif, weight: .semibold)
  /// Un titre de section.
  public static let title = Font.system(.title, design: .serif, weight: .semibold)
  /// Un titre de carte.
  public static let heading = Font.system(.title3, design: .serif, weight: .semibold)
  /// Le corps du texte.
  public static let body = Font.system(.body)
  /// Le corps, en appuyé.
  public static let bodyStrong = Font.system(.body, weight: .semibold)
  /// Ce qui accompagne : sous-titres, dates, lieux.
  public static let secondary = Font.system(.subheadline)
  /// La ligne au-dessus d'un titre — en capitales, donc interlettrée.
  public static let eyebrow = Font.system(.caption, weight: .semibold)
  /// Une légende.
  public static let caption = Font.system(.caption)
  /// Un terme technique cité comme tel.
  public static let code = Font.system(.callout, design: .monospaced)
  /// Un chiffre mis en avant. `.rounded` parce qu'un grand nombre en serif
  /// devient décoratif, et qu'on veut qu'il se lise.
  public static let metric = Font.system(size: Tokens.TypeScale.large, weight: .semibold, design: .rounded)
}

public extension View {
  /// L'interlettrage des capitales.
  ///
  /// Une capitale a besoin d'air, et le CV en PDF l'a appris durement : à
  /// `0,09 em`, `pdftotext` extrayait « COMPÉT ENCES ». Un lecteur
  /// automatique de CV lit alors des mots qui n'existent pas. La valeur est
  /// restée mesurée, jamais « au jugé ».
  func eyebrowStyle() -> some View {
    self
      .font(Typography.eyebrow)
      .textCase(.uppercase)
      .tracking(0.6)
      .foregroundStyle(Color.ink3)
  }
}
