import Domain

public extension AppearancePreference {
  /// `nil` means "follow the device", which is what SwiftUI's
  /// `preferredColorScheme` expects for that case — not a third scheme.
  ///
  /// The mapping lives in `Presentation` and returns a plain flag rather than a
  /// `ColorScheme`, because naming SwiftUI's type here would be the one import
  /// this layer must not have.
  var isDarkForced: Bool? {
    switch self {
    case .system: nil
    case .light: false
    case .dark: true
    }
  }
}
