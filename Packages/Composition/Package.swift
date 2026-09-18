// swift-tools-version: 6.2
import PackageDescription

/// The composition root — the one place allowed to know everyone.
///
/// ## Why one package may see everything
///
/// Somebody has to say that `PortfolioReading` is answered by
/// `PortfolioRepository`, which talks HTTP through `URLSessionHTTPClient` and
/// caches through `FileStore`. If no module were allowed to name both a port
/// and its implementation, nothing would ever be wired.
///
/// The discipline is that there is **exactly one** such module, it is this one,
/// and it contains no logic worth testing — it constructs and it assembles.
/// Every decision it makes is a decision about *which object*, never about
/// *what happens*.
///
/// That is also why the dependency list below is long and nobody else's is:
/// reading it gives the full graph of the application in eight lines.
let package = Package(
  name: "Composition",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Composition", targets: ["Composition"])],
  dependencies: [
    .package(path: "../Domain"),
    .package(path: "../Networking"),
    .package(path: "../Persistence"),
    .package(path: "../Data"),
    .package(path: "../Presentation"),
    .package(path: "../DesignSystem"),
    .package(path: "../Features"),
  ],
  targets: [
    .target(
      name: "Composition",
      dependencies: [
        .product(name: "Domain", package: "Domain"),
        .product(name: "Networking", package: "Networking"),
        .product(name: "Persistence", package: "Persistence"),
        .product(name: "Data", package: "Data"),
        .product(name: "Presentation", package: "Presentation"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "Features", package: "Features"),
      ],
      swiftSettings: .strict
    ),

    // The dependency graph is itself under test.
    //
    // The compiler already refuses a forbidden `import` — but nothing would
    // stop someone **adding the dependency to a manifest**, and the compiler
    // would then agree. This suite reads every `Package.swift` in the
    // repository and refuses the edges that must not exist.
    //
    // It lives here because this is the only package that can see all the
    // others; it reads their manifests from disk, walking up from `#filePath`.
    .testTarget(name: "CompositionTests", dependencies: ["Composition"], swiftSettings: .strict),
    .testTarget(name: "ArchitectureTests", swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
