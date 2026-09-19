import DesignSystem
import SwiftUI

/// A card that answers the finger that presses it.
///
/// ## Why this exists
///
/// Half the taps in this app land on a card, not on a button: a case study, a
/// depth topic, an app in the grid. Every one of them was a `Button` wearing
/// `.buttonStyle(.plain)` — which does exactly what it says and gives **no
/// feedback at all**. The row lit up nowhere, scaled nowhere, and the push
/// arrived a beat later with nothing in between.
///
/// That gap is one of the things that makes an interface feel like a web page:
/// on the web a link is a link and the browser answers for you; on iOS, a
/// control that does not answer the touch reads as a control that did not
/// register it. People press again.
///
/// The measure is deliberately smaller than a button's: a 300-point card
/// shrinking as much as a 44-point capsule looks like the screen moved.
public struct PressableCardStyle: ButtonStyle {
  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? Tokens.Layout.pressedScale : 1)
      .opacity(configuration.isPressed ? Tokens.Opacity.hairlineOnGlass : 1)
      .animation(Motion.interactive, value: configuration.isPressed)
  }
}

public extension ButtonStyle where Self == PressableCardStyle {
  /// For a card, a row, a grid cell — anything tappable that is not a button.
  static var pressableCard: PressableCardStyle { PressableCardStyle() }
}
