import Domain
import Foundation
@testable import Data

/// No seed at all — a bare first launch, with nothing on the device.
///
/// It lives in the **test target** and not in `Sources`: it is a double, it is
/// used by nothing that ships, and a double compiled into the app is weight
/// carried for nobody. It was `public` in `Sources` until the visibility pass
/// found it had no consumer outside its own package.
struct EmptySeedStub: SeedProviding {
  let builtAt = Date.distantPast
  func data(for language: Language) -> Data? { nil }
}
