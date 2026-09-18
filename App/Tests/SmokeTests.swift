import Testing
@testable import Amissan

/// Le minimum que l'hôte doit garantir : l'application se construit et se
/// lance. Tout le reste est testé dans `AmissanKit`, sans simulateur.
struct SmokeTests {
  @Test("l'application se compose sans lever")
  func appComposes() {
    _ = AmissanApp()
  }
}
