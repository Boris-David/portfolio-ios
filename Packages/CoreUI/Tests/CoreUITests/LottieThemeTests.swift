import DesignSystem
import Foundation
import Testing
@testable import CoreUI

/// The theme swap is wired to **layer names inside a JSON file**, which is the
/// most fragile kind of coupling there is: renaming a layer breaks it, the build
/// says nothing, and the animation simply keeps its light colours on dark paper.
///
/// That is precisely the failure this suite exists for. It is not testing that
/// Lottie works; it is testing that the two halves still agree.
struct LottieThemeTests {
  /// Every keypath names a layer the file actually has.
  ///
  /// A keypath that matches nothing is not an error in Lottie — the value
  /// provider is simply never applied, and the animation renders unchanged.
  /// Silent, and invisible in the one theme the author happened to be looking at.
  @Test("every tint keypath names a layer the file declares", arguments: LottieCatalogue.allCases)
  func keypathsMatchLayers(_ animation: LottieCatalogue) throws {
    let layers = try layerNames(of: animation)
    for tint in animation.tints {
      let layer = String(tint.keypath.prefix { $0 != "." })
      #expect(
        layers.contains(layer),
        "\(animation) tints \"\(layer)\", which \(animation.fileName).json does not declare — the swap would silently do nothing"
      )
    }
  }

  /// Every layer that carries colour is tinted.
  ///
  /// The mirror of the test above: a layer added to the file and forgotten here
  /// keeps its light colour while everything around it moves, which reads as a
  /// rendering bug rather than an omission.
  @Test("every layer the file declares is tinted", arguments: LottieCatalogue.allCases)
  func layersAreAllTinted(_ animation: LottieCatalogue) throws {
    let tinted = Set(animation.tints.map { String($0.keypath.prefix { $0 != "." }) })
    for layer in try layerNames(of: animation) {
      #expect(
        tinted.contains(layer),
        "\(animation.fileName).json has a layer \"\(layer)\" that no tint covers — it would stay light on dark paper"
      )
    }
  }

  /// The two themes must actually differ, or the swap is ceremony.
  ///
  /// It would pass trivially if a token were defined with the same value twice —
  /// which is exactly the mistake `TokensTests` guards for colours in general,
  /// and worth repeating here because these four are the ones that escaped the
  /// dynamic-colour mechanism in the first place.
  @Test("a tinted colour is not the same in both themes", arguments: LottieCatalogue.allCases)
  func themesDiffer(_ animation: LottieCatalogue) {
    for tint in animation.tints {
      #expect(
        tint.palette.light != tint.palette.dark,
        "\(animation) tints with a colour identical in both themes — the swap changes nothing"
      )
    }
  }

  private func layerNames(of animation: LottieCatalogue) throws -> [String] {
    let url = try #require(
      Bundle.coreUI.url(forResource: animation.fileName, withExtension: "json"),
      "\(animation.fileName).json is missing from the bundle"
    )
    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    let layers = try #require((json as? [String: Any])?["layers"] as? [[String: Any]])
    return layers.compactMap { $0["nm"] as? String }
  }
}
