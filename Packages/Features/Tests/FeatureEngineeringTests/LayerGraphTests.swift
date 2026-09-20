import Foundation
import Localization
import Testing
import ViewKit

@testable import FeatureEngineering

/// **The architecture screen is checked against the architecture.**
///
/// `EngineeringRecord.layers` is a second, hand-written copy of the package
/// graph: the manifests are the first. A second copy drifts — and this one had.
/// It named `Persistence` and `Composition`, two modules that never existed
/// under those names, while `Core`, `CoreUI` and `Localization` were missing
/// from a screen whose entire subject is the shape of this app.
///
/// Nothing caught it, because nothing compared the two. `DependencyGraphTests`
/// reads the manifests, but it lives in the application target and `package`
/// visibility stops at the package boundary, so it cannot see this list. This
/// suite is inside `Features`, where it can.
///
/// What it does **not** do is derive the list from the manifests: the screen
/// would then describe itself, always agreeing, proving nothing. The list is
/// declared, and the manifests refuse it when it is wrong.
struct LayerGraphTests {
  /// The composition root is an Xcode target, not a package: it has no
  /// `Package.swift` to read. It is checked separately, against the rule that
  /// defines it — it names every layer.
  private static let compositionRoot = "Amissan"

  private static let packagesDirectory: URL = {
    var url = URL(fileURLWithPath: #filePath)
    // …/Packages/Features/Tests/FeatureEngineeringTests/LayerGraphTests.swift
    for _ in 0..<4 { url.deleteLastPathComponent() }
    return url
  }()

  private static let manifests: [String: String] = {
    let names = (try? FileManager.default.contentsOfDirectory(
      atPath: packagesDirectory.path
    )) ?? []
    var found: [String: String] = [:]
    for name in names where !name.hasPrefix(".") {
      let manifest = packagesDirectory
        .appendingPathComponent(name)
        .appendingPathComponent("Package.swift")
      if let text = try? String(contentsOf: manifest, encoding: .utf8) {
        found[name] = text
      }
    }
    return found
  }()

  /// The packages a manifest declares — `.package(path: "../X")` is what
  /// actually grants access, and therefore what the screen must draw.
  private func declaredPackages(of layer: String) -> Set<String> {
    guard let manifest = Self.manifests[layer] else { return [] }
    let pattern = /\.package\(path: "\.\.\/([A-Za-z]+)"\)/
    return Set(manifest.matches(of: pattern).map { String($0.1) })
  }

  @Test("the manifests were found at all")
  func manifestsAreReadable() {
    #expect(
      Self.manifests.count >= 9,
      "read \(Self.manifests.count) manifests under \(Self.packagesDirectory.path) — the walk from #filePath is wrong, and every assertion below would pass on an empty set"
    )
  }

  @Test("the screen names every package, and names nothing else")
  func layersMatchThePackagesOnDisk() {
    let named = Set(EngineeringRecord.layers.map(\.name))
    let onDisk = Set(Self.manifests.keys).union([Self.compositionRoot])

    #expect(
      named == onDisk,
      "the screen announces \(named.sorted()) and the repository holds \(onDisk.sorted())"
    )
  }

  @Test("every arrow drawn is an arrow the manifest grants")
  func dependenciesMatchTheManifests() {
    for layer in EngineeringRecord.layers where layer.name != Self.compositionRoot {
      #expect(
        Set(layer.dependsOn) == declaredPackages(of: layer.name),
        "\(layer.name) claims \(layer.dependsOn.sorted()) and its manifest declares \(declaredPackages(of: layer.name).sorted())"
      )
    }
  }

  /// The one layer whose dependency list is *supposed* to be long: assembling
  /// is the only thing it does, so a name missing here means a layer nobody
  /// wires.
  @Test("the composition root names every layer, which is what makes it the root")
  func compositionRootNamesEveryLayer() {
    let root = EngineeringRecord.layers.first { $0.name == Self.compositionRoot }

    #expect(root != nil, "no composition root in the list")
    #expect(Set(root?.dependsOn ?? []) == Set(Self.manifests.keys))
  }

  /// A layer only ever appears after everything it names. It is how the screen
  /// reads top to bottom, and it is only possible because the graph is acyclic.
  @Test("the list reads leaves first")
  func layersAreListedInDependencyOrder() {
    var seen: Set<String> = []
    for layer in EngineeringRecord.layers {
      #expect(
        Set(layer.dependsOn).isSubset(of: seen),
        "\(layer.name) is listed before \(Set(layer.dependsOn).subtracting(seen).sorted())"
      )
      seen.insert(layer.name)
    }
  }

  /// Every identity has both of its sentences, in both languages. A layer added
  /// to the list with no catalogue entry renders its own key on screen.
  @Test("every layer says what it is responsible for, and what keeps it honest")
  func everyLayerHasItsSentences() {
    for layer in EngineeringRecord.layers {
      for key in [layer.responsibilityKey, layer.ruleKey] {
        for language in ["fr", "en"] {
          #expect(
            TextCatalogue.engineering.contains(key.identifier, in: language),
            "\(key.identifier) is missing from the \(language) catalogue"
          )
        }
      }
    }
  }

  /// And the other direction, which is the one that actually rotted:
  /// `layer.persistence.rule` and `layer.composition.rule` outlived the modules
  /// they described, waiting to be rendered again. A key is computed here —
  /// `TextKey("layer.\(id).rule")` — so `Scripts/check-strings.sh` cannot see
  /// it, and the catalogue is read as a file instead.
  @Test("no sentence survives the layer it described")
  func theCatalogueCarriesNoOrphanedLayer() throws {
    // Read from the source tree, like the manifests above: Xcode **compiles**
    // an `.xcstrings` into `.lproj` directories even when the manifest says
    // `.copy`, so a bundled one is no longer the file a reader would open.
    let url = Self.packagesDirectory
      .appendingPathComponent("Features/Sources/Features/Engineering/Resources/Localizable.xcstrings")
    let catalogue = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    let strings = try #require((catalogue as? [String: Any])?["strings"] as? [String: Any])

    let declared = Set(EngineeringRecord.layers.flatMap {
      [$0.responsibilityKey.identifier, $0.ruleKey.identifier]
    })
    let carried = Set(strings.keys.filter { $0.hasPrefix("layer.") })

    #expect(
      carried.subtracting(declared).isEmpty,
      "the catalogue still holds \(carried.subtracting(declared).sorted()), which no layer names"
    )
  }
}
