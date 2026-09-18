import Testing
@testable import Amissan

/// The minimum the host must guarantee: the app builds and launches. Everything
/// else is tested in the packages, without a simulator.
struct SmokeTests {
  @Test("the app composes without throwing")
  func appComposes() {
    _ = AmissanApp()
  }
}
