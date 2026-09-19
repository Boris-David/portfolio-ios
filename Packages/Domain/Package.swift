// swift-tools-version: 6.2
import PackageDescription

/// The domain — entities and ports, and **nothing else**.
///
/// ## Why the empty `dependencies:` line is the whole point
///
/// This layer used to be one target among others. "The domain depends on
/// nothing" was then a line in a manifest anyone could extend, plus a test that
/// read the manifest back to check nobody had. A rule guarding a rule.
///
/// As a package the sentence changes meaning. There is no dependency to declare
/// a product from, so importing anything but the standard library and
/// Foundation **cannot resolve**. Not "is forbidden" — cannot resolve. The
/// empty array below is the strongest statement in this repository.
///
/// What it buys, concretely:
///
/// - the domain builds on any platform Swift targets. It has never seen
///   SwiftUI, `URLSession`, or a serialisation format;
/// - its tests need no simulator, no fixtures and no doubles — there is nothing
///   to double;
/// - a change of transport, of storage or of user interface cannot reach it.
let package = Package(
  name: "Domain",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Domain", targets: ["Domain"])],
  dependencies: [],
  targets: [
    .target(name: "Domain", swiftSettings: .strict),
    .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// Settings every target in the repository turns on.
  ///
  /// `ExistentialAny` (SE-0335) makes `any` **mandatory** in front of every
  /// existential. Without it, `let client: HTTPClient` compiles and silently
  /// boxes a value behind dynamic dispatch; with it, the compiler demands
  /// `any HTTPClient` and every such site is visible by reading. A performance
  /// characteristic you can see is one you can argue about.
  static var strict: [SwiftSetting] {
    [.enableUpcomingFeature("ExistentialAny")]
  }
}
