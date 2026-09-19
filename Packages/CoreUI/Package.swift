// swift-tools-version: 6.2
import PackageDescription

/// The component library — and the **only** package that knows which libraries
/// draw things.
///
/// ## Why the third-party dependencies live here and nowhere else
///
/// Stated plainly by the author: *"I must not have `import Textual` in my code
/// files, but `import CoreUI` — so that the day I change library, I do not have
/// to change an import."*
///
/// That is the wrapper's whole job, and it is not aesthetic. `Textual`, `Lottie`
/// and `PDFKit` are named in exactly one file each — `MarkdownText`,
/// `LottieAnimation`, `PDFPreview`. Everything above depends on those three
/// types, whose signatures say nothing about who renders them.
///
/// Replacing Textual then costs one file, and the interfaces do not move. The
/// same swap with `import Textual` scattered through thirty views costs thirty
/// files and a diff nobody can review.
///
/// And it is enforced, not hoped for: no other manifest declares these packages,
/// so `import Textual` elsewhere answers "no such module".
///
/// ## Why this is not `DesignSystem`
///
/// `DesignSystem` is the **visual language**: tokens, colour, typography,
/// motion. Values. It draws nothing, and that is what lets it be consumed by
/// something that is not SwiftUI — a PDF generator, an extension, a watchOS app
/// one day.
///
/// `CoreUI` is what is **built from** that language: components, wrappers,
/// styles. A component knows its palette; a palette knows no component. The
/// dependency runs one way, and this file is where that is declared.
let package = Package(
  name: "CoreUI",
  platforms: [.iOS(.v18)],
  products: [.library(name: "CoreUI", targets: ["CoreUI"])],
  dependencies: [
    .package(path: "../DesignSystem"),

    // Vector animation that neither SwiftUI nor Core Animation can read:
    // interpolated Bézier paths, masks, motion along a curve. Reimplementing an
    // After Effects interpreter is not "less convenient", it is a project of its
    // own — which is exactly the test a dependency has to pass.
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),

    // Textual: Markdown rendered into a native `AttributedString`. The same
    // author maintained MarkdownUI, now in maintenance mode and pointing here.
    //
    // ⚠️ A **0.x** version: semver promises nothing before 1.0, and a minor
    // release is allowed to break. Hence `upToNextMinor` rather than `from` —
    // patches are taken, minor bumps are a decision.
    .package(url: "https://github.com/gonzalezreal/textual", .upToNextMinor(from: "0.5.0")),
  ],
  targets: [
    .target(
      name: "CoreUI",
      dependencies: [
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "Lottie", package: "lottie-ios"),
        .product(name: "Textual", package: "textual"),
      ],
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),
    .testTarget(name: "CoreUITests", dependencies: ["CoreUI"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
