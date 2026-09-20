import Foundation

public extension Bundle {
  /// This package's resource bundle — animations, assets.
  ///
  /// `Bundle.module` is **internal** to each target: from a screen, it would
  /// name that screen's bundle, not this one. Exposing it explicitly avoids the
  /// silent "resource not found" that takes an hour to diagnose.
  static let coreUI = Bundle.module
}
