import Foundation
import Testing
@testable import CoreUI

/// The animations are hand-written JSON, and hand-written JSON has a failure
/// mode no compiler sees: **Lottie answers a mistake with an empty frame**. A
/// missing file, a layer whose out point stops before the composition does, a
/// colour typed one digit off — none of them crash, none of them warn, and all
/// of them reach the App Store as a hole in the screen.
///
/// So this suite reads the files the way Lottie will and asserts what the
/// catalogue promises about them.
struct LottieCatalogueTests {
  /// The canvas the hand-authored files share.
  ///
  /// `signature.json` set 120 as the height and 60 as the frame rate; the three
  /// state animations keep the height and square it, because they are shown in
  /// a slot that has no reason to be wide. Written here rather than in the
  /// catalogue: it is a fact about the files, and the only thing that cares is
  /// this check.
  private let canvasSide: Double = 120

  @Test(
    "every animation resolves to a file that is really in the bundle",
    arguments: LottieCatalogue.allCases
  )
  func resolvesToABundledFile(animation: LottieCatalogue) {
    // `Bundle.module` is internal to each target, so a screen asking for a
    // resource gets its own bundle and finds nothing — silently. `.coreUI`
    // names the right one, and this is the check that the name still matches a
    // file after somebody renames one.
    #expect(
      Bundle.coreUI.url(forResource: animation.fileName, withExtension: "json") != nil,
      "\(animation).fileName is '\(animation.fileName)', and no such resource exists"
    )
  }

  @Test(
    "every file parses, at the frame rate and the length the catalogue declares",
    arguments: LottieCatalogue.allCases
  )
  func declaresItsFrameRateAndLength(animation: LottieCatalogue) throws {
    let composition = try composition(of: animation)

    #expect(composition["fr"] as? Double == LottieCatalogue.frameRate)
    #expect(composition["ip"] as? Double == 0)
    // `frameCount` is written as a sum of `Tokens.Duration` values, so this
    // fails the day somebody retunes a duration token without retiming the
    // file. That is the only link there can be between a generated token and a
    // number typed into JSON.
    #expect(composition["op"] as? Double == animation.frameCount)
  }

  @Test("the state animations are drawn on a square canvas")
  func areSquare() throws {
    for animation in [LottieCatalogue.empty, .unreachable, .downloaded] {
      let composition = try composition(of: animation)
      #expect(composition["w"] as? Double == canvasSide, "\(animation) is not \(canvasSide) wide")
      #expect(composition["h"] as? Double == canvasSide, "\(animation) is not \(canvasSide) tall")
    }
  }

  /// Asserting against `Tokens` rather than re-parsing `design/tokens*.json`,
  /// and the reason is not preference: these tests run in a simulator, whose
  /// sandbox has no repository to read. `design/tokens.json` would have to be
  /// copied in as a test resource — a second copy of the source of truth, which
  /// is the very thing the token pipeline exists to prevent.
  ///
  /// `Tokens.swift` **is** those files, generated, and `./Scripts/tokens.mjs
  /// --check` already fails if the two have drifted. Checking the JSON against
  /// the generated Swift therefore closes the loop with no second copy.
  @Test(
    "every colour in a file is a design token, and every declared token is used",
    arguments: LottieCatalogue.allCases
  )
  func colorsComeFromTheTokens(animation: LottieCatalogue) throws {
    let composition = try composition(of: animation)
    let used = Set(colorChannels(in: composition).map(rounded))
    let declared = Set(animation.palette.map(rounded))

    #expect(!used.isEmpty, "\(animation) declares no colour at all — it would render invisible")
    // One direction catches an off-brand colour typed into the JSON…
    #expect(used.subtracting(declared).isEmpty, "\(animation) uses colours outside its palette")
    // …the other catches a palette entry left behind by an edit, which would
    // turn this suite's documentation into a comfortable lie.
    #expect(declared.subtracting(used).isEmpty, "\(animation) declares colours it never draws")
  }

  @Test(
    "every layer stays on screen for the whole composition",
    arguments: LottieCatalogue.allCases
  )
  func layersCoverTheWholeComposition(animation: LottieCatalogue) throws {
    let composition = try composition(of: animation)
    let layers = try #require(composition["layers"] as? [[String: Any]])

    #expect(!layers.isEmpty)
    for layer in layers {
      let name = layer["nm"] as? String ?? "unnamed"
      // A layer whose own in/out points are narrower than the composition's
      // simply stops being drawn partway through, and the only symptom is a
      // shape that disappears. Nothing reports it.
      #expect(layer["ip"] as? Double == 0, "layer '\(name)' of \(animation) starts late")
      #expect(
        layer["op"] as? Double == animation.frameCount,
        "layer '\(name)' of \(animation) ends before the composition does"
      )
      // Shape layers only: no images, no text, no expressions in these files.
      #expect(layer["ty"] as? Double == 4, "layer '\(name)' of \(animation) is not a shape layer")
    }
  }

  // MARK: - Reading the files

  private func composition(of animation: LottieCatalogue) throws -> [String: Any] {
    let url = try #require(
      Bundle.coreUI.url(forResource: animation.fileName, withExtension: "json"),
      "\(animation.fileName).json is missing from the bundle"
    )
    let parsed = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    return try #require(parsed as? [String: Any], "\(animation.fileName).json is not an object")
  }

  /// Every `[r, g, b, a]` a stroke or a fill declares, anywhere in the tree.
  ///
  /// Walking the whole document rather than the shapes it is supposed to
  /// contain: a colour smuggled into a layer style would be exactly the one
  /// worth catching, and a check that only looks where it expects to find
  /// things finds only what it expected.
  private func colorChannels(in node: Any) -> [[Double]] {
    if let object = node as? [String: Any] {
      return object.flatMap { key, value -> [[Double]] in
        if key == "c",
           let color = value as? [String: Any],
           let channels = color["k"] as? [Double],
           channels.count == 4 {
          return [Array(channels.prefix(3))]
        }
        return colorChannels(in: value)
      }
    }
    if let array = node as? [Any] {
      return array.flatMap(colorChannels(in:))
    }
    return []
  }

  /// To four decimals — the precision `Scripts/tokens.mjs` writes into
  /// `Tokens.swift`, and therefore the precision the JSON was authored at.
  private func rounded(_ channels: [Double]) -> [Double] {
    channels.map { ($0 * 10_000).rounded() / 10_000 }
  }
}
