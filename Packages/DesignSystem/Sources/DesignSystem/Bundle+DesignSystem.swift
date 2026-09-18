import Foundation

public extension Bundle {
  /// The design system's resource bundle — animations, assets.
  ///
  /// `Bundle.module` is **internal** to each target: from a feature, it would
  /// name that feature's bundle, not this one. Exposing it explicitly avoids the
  /// silent "resource not found" that takes an hour to diagnose.
  static let designSystem = Bundle.module
}
