import Testing
@testable import DesignSystem

/// The design values **descend** from `design/tokens.json`, the same source as
/// the website's CSS. These tests guard the properties generation must preserve
/// — not the values themselves, which are allowed to change.
struct TokensTests {
  @Test("every colour carries a distinct light and dark value", arguments: [
    Tokens.Color.paper, Tokens.Color.ink, Tokens.Color.accent,
    Tokens.Color.line, Tokens.Color.onAccent, Tokens.Color.ok,
  ])
  func paletteHasBothThemes(_ palette: Tokens.Palette) {
    #expect(palette.light != palette.dark, "a colour identical in both themes is a colour somebody forgot")
  }

  @Test("components stay within [0, 1]", arguments: [
    Tokens.Color.paper, Tokens.Color.ink, Tokens.Color.accent,
  ])
  func componentsAreNormalised(_ palette: Tokens.Palette) {
    for components in [palette.light, palette.dark] {
      for channel in [components.red, components.green, components.blue] {
        #expect((0...1).contains(channel))
      }
    }
  }

  /// The scale is 4 points, and strictly increasing. A value that broke the
  /// order would produce inconsistent spacing without breaking anything.
  @Test("the spacing scale increases and stays a multiple of 4")
  func spacingScale() {
    let scale = [
      Tokens.Space.s1, Tokens.Space.s2, Tokens.Space.s3, Tokens.Space.s4,
      Tokens.Space.s5, Tokens.Space.s6, Tokens.Space.s7, Tokens.Space.s8, Tokens.Space.s9,
    ]
    #expect(scale == scale.sorted())
    for step in scale { #expect(step.truncatingRemainder(dividingBy: 4) == 0) }
  }

  /// The type scale is aligned with Dynamic Type — base 17, like iOS.
  @Test("the type scale starts from the iOS body size")
  func typeScale() {
    #expect(Tokens.TypeScale.body == 17)
    #expect(Tokens.TypeScale.caption < Tokens.TypeScale.body)
    #expect(Tokens.TypeScale.large > Tokens.TypeScale.title1)
  }

  /// The smallest acceptable touch target. The value comes from the tokens, so
  /// from the same place as the website — and it never drops below 44.
  @Test("the minimum touch target honours Apple's guidance")
  func touchTarget() {
    #expect(Tokens.Accessibility.minimumTouchTarget >= 44)
  }

  /// The curves are shared with the website: a card unfolding has the same
  /// momentum in the browser and on the phone.
  @Test("the motion curves are valid Béziers", arguments: [
    Tokens.Ease.out, Tokens.Ease.soft, Tokens.Ease.io, Tokens.Ease.back,
  ])
  func easingCurves(_ curve: Tokens.Curve) {
    // The x values of a CSS curve are bounded; the y values are not, which is
    // exactly what makes a bounce possible (`back` overshoots 1).
    #expect((0...1).contains(curve.x1))
    #expect((0...1).contains(curve.x2))
  }
}
