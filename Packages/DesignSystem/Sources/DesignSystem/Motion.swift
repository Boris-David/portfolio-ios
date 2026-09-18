import SwiftUI

/// Motion, with **the same curves as the website**.
///
/// `Tokens.Ease` carries cubic Bézier curves, in the form CSS and
/// `Animation.timingCurve` both expect. The two platforms therefore share the
/// same feel — a card unfolding has the same momentum in the browser and on the
/// phone.
public enum Motion {
  /// An element arriving: quick to start, long to settle.
  public static let entrance = animation(Tokens.Ease.out, duration: Tokens.Duration.entrance)
  /// A card unfolding — the longest, because it is being watched.
  public static let disclosure = animation(Tokens.Ease.soft, duration: Tokens.Duration.disclosure)
  /// A there-and-back: a toggle, a change of state.
  public static let toggle = animation(Tokens.Ease.io, duration: Tokens.Duration.toggle)
  /// A measured bounce, for what should catch the eye once.
  public static let pop = animation(Tokens.Ease.back, duration: Tokens.Duration.pop)

  public static func animation(_ curve: Tokens.Curve, duration: Double) -> Animation {
    .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2, duration: duration)
  }
}

public extension View {
  /// Animates, **unless** the person asked for less motion.
  ///
  /// `prefers-reduced-motion` is not a dial, it is a switch: halving an
  /// animation that causes nausea still causes nausea. The state change stays
  /// instantaneous, and nothing disappears.
  func motion(_ animation: Animation, value: some Equatable, reduced: Bool) -> some View {
    self.animation(reduced ? nil : animation, value: value)
  }
}

/// Reads the system's reduced-motion preference.
///
/// Wrapped in a type rather than read by hand in each view: an accessibility
/// preference you have to remember to consult is a preference you will forget
/// somewhere.
@propertyWrapper
public struct ReducedMotion: DynamicProperty {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init() {}

  public var wrappedValue: Bool { reduceMotion }
}
