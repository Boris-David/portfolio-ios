import SwiftUI

/// Liquid Glass on iOS 26, and a deliberate fallback on iOS 18.
///
/// ## Why a layer rather than `if #available` scattered around
///
/// The app targets **iOS 18 and up**, and builds against the iOS 26 SDK. Both
/// worlds therefore live in the same binary. Three ways to cope:
///
/// 1. *target iOS 26 only* — this loses the devices that have not moved to the
///    major version, which for the first months is a share counted in tens of
///    per cent;
/// 2. *sprinkle `if #available(iOS 26, *)` through the views* — it works, and
///    after thirty screens nobody knows what an iOS 18 user sees any more. The
///    fallback is tested nowhere because it is named nowhere;
/// 3. **name the intent and let the layer decide** — `.navigationGlass()` says
///    *"this is a navigation surface"*. How it renders is decided here, in one
///    place, and both renderings sit side by side in the previews.
///
/// This is the third. The cost of a moving SDK is paid once, in this file,
/// instead of being spread everywhere.
///
/// ## What glass is **not** applied to
///
/// Liquid Glass is a material of the **navigation** layer: bars, buttons,
/// accessories. Putting it on content — a list, a paragraph, an image — degrades
/// text contrast and blurs the hierarchy: everything starts floating, so nothing
/// stands out. The rule is held by the naming: there is no `contentGlass()`.
public extension View {
  /// A navigation surface: a floating bar, a group of controls, a button laid
  /// over content.
  ///
  /// - Parameters:
  ///   - shape: the shape cut out. A capsule by default, because that is what
  ///     the system uses for its own floating controls.
  ///   - tint: a tint, to signal an active state. `nil` most of the time — a
  ///     material tinted everywhere is just a colour again.
  ///   - interactive: the glass reacts to touch. Reserved for what genuinely is
  ///     touchable, otherwise the surface promises an action that does not exist.
  @ViewBuilder
  func navigationGlass(
    // `InsettableShape` and not `Shape`: it is the protocol that brings
    // `strokeBorder`, which strokes **inwards**. An ordinary `stroke` spills by
    // half its width and clips the content next to it.
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
      // The fallback is not "the same thing, worse": it is the material iOS 18
      // uses for its own bars. An iOS 18 user sees an iOS 18 app, not a failed
      // imitation of iOS 26.
      self
        .background {
          shape
            .fill(.ultraThinMaterial)
            // The tint sits **on top of** the material, not underneath: under
            // it, the blur would have washed it out to nothing.
            .overlay(shape.fill(tint?.opacity(Tokens.Opacity.tintOnMaterial) ?? .clear))
            .overlay(shape.strokeBorder(Color.line.opacity(Tokens.Opacity.hairlineOnGlass), lineWidth: Tokens.Stroke.hairline))
        }
        .shadow(
          color: .black.opacity(Tokens.Elevation.floating.opacity),
          radius: Tokens.Elevation.floating.radius,
          y: Tokens.Elevation.floating.y
        )
    }
  }

  /// The tab bar shrinks as you read down the content.
  ///
  /// iOS 26 only: on iOS 18 the bar stays, which is its normal behaviour and not
  /// a defect.
  @ViewBuilder
  func minimizingTabBarOnScroll() -> some View {
    if #available(iOS 26.0, *) {
      self.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      self
    }
  }
}
