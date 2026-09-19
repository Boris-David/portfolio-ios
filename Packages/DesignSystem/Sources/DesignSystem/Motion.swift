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

  /// A finger's answer: a press, a selection, a card taking the touch.
  ///
  /// ## Why this one is not a token curve
  ///
  /// The four above are shared with the website's CSS, and that is the point:
  /// a card unfolds with the same momentum in a browser and on the phone.
  ///
  /// This one answers a **finger**, and a finger is not a thing the web has.
  /// `.snappy` is a spring, so it carries velocity: interrupt it mid-way — lift
  /// off early, press again — and it resolves from where it actually is rather
  /// than restarting. A timing curve cannot do that, and the difference is felt
  /// rather than seen, which is exactly what separates a native control from a
  /// web one.
  public static let interactive = Animation.snappy(duration: Tokens.Duration.toggle)

  public static func animation(_ curve: Tokens.Curve, duration: Double) -> Animation {
    .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2, duration: duration)
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
