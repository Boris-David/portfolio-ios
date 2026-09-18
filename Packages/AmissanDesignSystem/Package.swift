// swift-tools-version: 6.2
import PackageDescription

/// The design system, as a **package of its own**.
///
/// ## Why a separate package and not just another target
///
/// Inside `AmissanKit`, "the design system must not know the domain" was a rule.
/// A rule held by a test, admittedly — but still a rule, and rules get bent.
///
/// Here it stops being a rule and becomes an **impossibility**: this package
/// does not depend on `AmissanKit`, so `import Domain` cannot compile. Nothing
/// to remember, nothing to check.
///
/// Two more things follow from the split, and they are the real point:
///
/// - **it is reusable.** A design system that cannot leave its application was
///   never a design system, it was a folder of views. This one builds, tests and
///   previews on its own;
/// - **it versions on its own.** The day it moves to its own repository, nothing
///   changes here but a URL.
///
/// The cost is one more manifest. That is the whole cost.
let package = Package(
  name: "AmissanDesignSystem",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
  ],
  dependencies: [
    // Vector animations that neither SwiftUI nor Core Animation can read:
    // interpolated Bézier paths, masks, motion along curves. Reimplementing an
    // After Effects interpreter is not "less convenient", it is a project of its
    // own — which is exactly the test a dependency has to pass.
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [.product(name: "Lottie", package: "lottie-ios")],
      resources: [.process("Resources")]
    ),
    .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
  ],
  swiftLanguageModes: [.v6]
)
