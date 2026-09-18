import Domain
import Foundation

/// The bundled seed: enough to show something on the very first launch, with no
/// network.
///
/// It is **produced at build time from the API** — `Scripts/seed.sh` — and never
/// written by hand. A hand-written seed would be a second source of truth,
/// exactly what the architecture removes everywhere else.
///
/// It is not a silent fallback: the screen says it is showing the seed and how
/// old it is. The difference with the website, which refuses any fallback, is
/// deliberate: the site is **built** on a machine with a network, whereas the
/// app is already in someone's hand, and that someone may be in a tunnel.
public struct BundledSeed: SeedProviding {
  /// This module's resource bundle.
  ///
  /// `Bundle.module` is **internal** to the target that declares it: it cannot
  /// appear in a public initialiser's default value. So it is exposed
  /// explicitly — which has the advantage of naming what is meant, instead of a
  /// `.module` nobody can tell the module of.
  public static let resources = Bundle.module

  private let bundle: Bundle
  public let builtAt: Date

  public init(bundle: Bundle = BundledSeed.resources, builtAt: Date? = nil) {
    self.bundle = bundle
    self.builtAt = builtAt ?? BundledSeed.compiledAt(bundle: bundle)
  }

  public func data(for language: Language) -> Data? {
    guard let url = bundle.url(forResource: "seed-\(language.rawValue)", withExtension: "json")
    else { return nil }
    return try? Data(contentsOf: url)
  }

  /// When the seed was made, read from the file itself.
  ///
  /// Not a compiled-in constant: that would be wrong the moment a build was
  /// replayed without regenerating the seed, and a wrong "stale since" is worse
  /// than none at all.
  public static func compiledAt(bundle: Bundle = BundledSeed.resources) -> Date {
    guard let url = bundle.url(forResource: "seed-fr", withExtension: "json"),
          let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
          let date = values.contentModificationDate
    else { return .distantPast }
    return date
  }
}
