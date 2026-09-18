import Testing
@testable import DesignSystem

/// Les valeurs de design **descendent** de `design/tokens.json`, la même source
/// que le CSS du site. Ces tests gardent les propriétés que la génération doit
/// préserver — pas les valeurs elles-mêmes, qui ont le droit de changer.
struct TokensTests {
  @Test("chaque couleur porte une valeur claire et une valeur sombre distinctes", arguments: [
    Tokens.Color.paper, Tokens.Color.ink, Tokens.Color.accent,
    Tokens.Color.line, Tokens.Color.onAccent, Tokens.Color.ok,
  ])
  func paletteHasBothThemes(_ palette: Tokens.Palette) {
    #expect(palette.light != palette.dark, "une couleur identique dans les deux thèmes est une couleur oubliée")
  }

  @Test("les composantes restent dans [0, 1]", arguments: [
    Tokens.Color.paper, Tokens.Color.ink, Tokens.Color.accent,
  ])
  func componentsAreNormalised(_ palette: Tokens.Palette) {
    for components in [palette.light, palette.dark] {
      for channel in [components.red, components.green, components.blue] {
        #expect((0...1).contains(channel))
      }
    }
  }

  /// L'échelle est de 4 points, et strictement croissante. Une valeur qui
  /// casserait l'ordre produirait des espacements incohérents sans rien casser.
  @Test("l'échelle d'espacement est croissante et multiple de 4")
  func spacingScale() {
    let scale = [
      Tokens.Space.s1, Tokens.Space.s2, Tokens.Space.s3, Tokens.Space.s4,
      Tokens.Space.s5, Tokens.Space.s6, Tokens.Space.s7, Tokens.Space.s8, Tokens.Space.s9,
    ]
    #expect(scale == scale.sorted())
    for step in scale { #expect(step.truncatingRemainder(dividingBy: 4) == 0) }
  }

  /// L'échelle typographique est alignée sur Dynamic Type — base 17, comme iOS.
  @Test("l'échelle typographique part du corps iOS")
  func typeScale() {
    #expect(Tokens.TypeScale.body == 17)
    #expect(Tokens.TypeScale.caption < Tokens.TypeScale.body)
    #expect(Tokens.TypeScale.large > Tokens.TypeScale.title1)
  }

  /// La plus petite cible tactile admissible. La valeur vient des tokens, donc
  /// du même endroit que le site — et elle ne descend jamais sous 44.
  @Test("la cible tactile minimale respecte la recommandation d'Apple")
  func touchTarget() {
    #expect(Tokens.Accessibility.minimumTouchTarget >= 44)
  }

  /// Les courbes sont partagées avec le site : une carte qui se déplie a le même
  /// élan dans le navigateur et sur le téléphone.
  @Test("les courbes de mouvement sont des Bézier valides", arguments: [
    Tokens.Ease.out, Tokens.Ease.soft, Tokens.Ease.io, Tokens.Ease.back,
  ])
  func easingCurves(_ curve: Tokens.Curve) {
    // Les abscisses d'une courbe CSS sont bornées ; les ordonnées non, ce qui
    // est précisément ce qui permet un rebond (`back` dépasse 1).
    #expect((0...1).contains(curve.x1))
    #expect((0...1).contains(curve.x2))
  }
}
