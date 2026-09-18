import SwiftUI

/// The style of floating buttons — glass on iOS 26, bordered on iOS 18.
public struct AdaptiveGlassButtonStyle: ButtonStyle {
  private let prominent: Bool

  public init(prominent: Bool = false) {
    self.prominent = prominent
  }

  public func makeBody(configuration: Configuration) -> some View {
    label(configuration)
      // Touch feedback is the same in both worlds: it is information, not
      // decoration, and it does not depend on the material.
      .scaleEffect(configuration.isPressed ? Tokens.Layout.pressedScale : 1)
      .animation(Motion.toggle, value: configuration.isPressed)
  }

  /// ⚠️ **`glassEffect` applies to the view, never to a background behind it.**
  ///
  /// The previous version put the glass inside a `.background { … }`. It
  /// compiles, it raises no warning — and the label **disappears**. iOS 26 glass
  /// is not a layer you stack behind: it is a treatment of the view it is
  /// applied to, and it composes its own content. Put in the background, it
  /// covers the text.
  ///
  /// Found on iPad, then recognised on iPhone — where I had taken it for a
  /// button simply hidden behind the tab bar. A misread screenshot is worth an
  /// unseen regression.
  ///
  /// And a **prominent** button does not render the same in both worlds.
  /// `Glass.tint(_:)` guarantees legibility on iOS 26; the same tint at low
  /// opacity over a translucent material gives, in light theme on iOS 18, white
  /// on pale. The fallback is a solid accent fill — what iOS 18 itself uses for
  /// a primary action.
  @ViewBuilder
  private func label(_ configuration: Configuration) -> some View {
    let content = configuration.label
      .font(Typography.bodyStrong)
      .foregroundStyle(prominent ? Color.onAccent : Color.ink)
      .padding(.horizontal, Tokens.Space.s4)
      .frame(minHeight: Tokens.Accessibility.minimumTouchTarget)

    if #available(iOS 26.0, *) {
      content.glassEffect(
        Glass.regular.tint(prominent ? Color.accent : nil).interactive(),
        in: Capsule()
      )
    } else if prominent {
      content.background(Capsule().fill(Color.accent))
    } else {
      content
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular))
    }
  }
}

public extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
  /// A secondary floating button.
  static var adaptiveGlass: AdaptiveGlassButtonStyle { AdaptiveGlassButtonStyle() }
  /// A screen's primary action — one per screen.
  static var adaptiveGlassProminent: AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(prominent: true)
  }
}
