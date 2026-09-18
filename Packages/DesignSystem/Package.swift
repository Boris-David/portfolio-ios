// swift-tools-version: 6.2
import PackageDescription

/// Colour, type, motion, and the components built from them.
///
/// ## Why a package and not a target
///
/// Inside one big package, "the design system must not know the domain" was a
/// rule — held by a test, but still a rule, and rules get bent. Here it is an
/// **impossibility**: this package does not depend on `Domain`, so
/// `import Domain` cannot resolve. Nothing to remember, nothing to check.
///
/// Two things follow, and they are the real point:
///
/// - **it is reusable.** A design system that cannot leave its application was
///   never a design system, it was a folder of views. This one builds, tests
///   and previews on its own;
/// - **it versions on its own.** The day it moves to its own repository,
///   nothing changes here but a URL.
///
/// ## Where its values come from
///
/// `Sources/DesignSystem/Generated/Tokens.swift` is **generated** by
/// `Scripts/tokens.mjs` from two files: the shared tokens in the portfolio hub,
/// and `design/tokens.ios.json` for what only makes sense on iOS. Editing it by
/// hand produces a design that drifts from the website with nothing to say so.
let package = Package(
  name: "DesignSystem",
  platforms: [.iOS(.v18)],
  products: [.library(name: "DesignSystem", targets: ["DesignSystem"])],
  dependencies: [
    // Vector animation that neither SwiftUI nor Core Animation can read:
    // interpolated Bézier paths, masks, motion along a curve. Reimplementing an
    // After Effects interpreter is not "less convenient", it is a project of its
    // own — which is exactly the test a dependency has to pass.
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [.product(name: "Lottie", package: "lottie-ios")],
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),
    .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
