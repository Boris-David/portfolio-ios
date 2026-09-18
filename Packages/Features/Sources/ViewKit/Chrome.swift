import Presentation
import SwiftUI

/// Reads the interface strings for the language currently on screen.
///
/// The chrome is **derived** from the language carried by the environment,
/// rather than being a second environment value of its own.
///
/// Two keys — one for the language, one for the chrome — could have contradicted
/// each other: forgetting to update one would have been enough. A single source
/// makes the contradiction impossible.
///
/// It lives in `ViewKit` and not in `Presentation` because `DynamicProperty` is
/// a SwiftUI protocol, and `Presentation` does not import SwiftUI — that is the
/// whole point of the layer.
@propertyWrapper
public struct Chrome: DynamicProperty {
  @Environment(\.contentLanguage) private var language

  public init() {}

  public var wrappedValue: AppChrome { .for(language) }
}
