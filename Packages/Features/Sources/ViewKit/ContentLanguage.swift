import Domain
import SwiftUI

public extension EnvironmentValues {
  /// The language **of the content on screen** — not the device's.
  ///
  /// This is the single value that decides the language of the whole interface.
  /// A string catalogue would have followed the device, and the device may ask
  /// for a language the source does not serve: tabs in one language above a body
  /// in the other.
  ///
  /// That is not hypothetical — it is the defect observed on the first launch,
  /// and it is what motivated this design.
  @Entry var contentLanguage: Language = .french
}
