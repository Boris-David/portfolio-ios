// swift-tools-version: 6.2
import PackageDescription

/// The **visual language**: colour, type, motion. Values, and nothing that
/// draws.
///
/// ## Why the components left
///
/// They moved to `CoreUI` on 2026-09-18, and the line between the two is worth
/// stating: a design system describes *what things look like*; a component
/// library *is* the things. Keeping both here made the package impossible to
/// consume from anywhere that is not SwiftUI.
///
/// Now it can be: a PDF generator, an app extension, a watchOS target one day.
/// A palette knows no component; a component knows its palette. The dependency
/// runs one way, and it is `CoreUI` that declares it.
///
/// ## Why a package and not a target
///
/// Inside one big package, "the design system must not know the domain" was a
/// rule — held by a test, but still a rule, and rules get bent. Here it is an
/// **impossibility**: this package does not depend on `Domain`, so
/// `import Domain` cannot resolve. Nothing to remember, nothing to check.
///
/// And it **versions on its own**. The day it moves to its own repository,
/// nothing changes here but a URL.
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
  // Empty, and that is the point. A design language that needed a rendering
  // library would not be a language, it would be a renderer.
  dependencies: [],
  targets: [
    .target(name: "DesignSystem", swiftSettings: .strict),
    .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
