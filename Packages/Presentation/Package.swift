// swift-tools-version: 6.2
import PackageDescription

/// What prepares content for display — and knows nothing about how it is drawn.
///
/// ## Why this package exists
///
/// It was extracted on 2026-09-18, from an observation by the author: *"for me
/// the adapter layer is what prepares the data for the UI"*. That layer did
/// exist — it was scattered through `FeatureKit`, mixed in with SwiftUI views,
/// and it had no name. Something without a name cannot be depended on
/// deliberately, and cannot be defended in review.
///
/// In Clean Architecture terms this is the **presenter** half of the interface
/// adapters ring. The other half — the gateways — is the `Data` package. They
/// sit on opposite sides of the domain and have no business sharing a name.
///
/// ## The invariant, and how it is held
///
/// **Nothing here imports SwiftUI.** That is the acid test of a presentation
/// layer: if it renders, it is a view; if it decides what to render, it belongs
/// here. So this package owns
///
/// - `ViewPhase` — the four states every screen can be in;
/// - `PortfolioStore` — the state holder, and where a domain error becomes a
///   sentence someone can read;
/// - `AppChrome` — every interface string, in both languages;
/// - `Formatting` — dates and durations turned into text;
/// - `Route`, `Sheet`, `Section`, `Router` — where navigation can go.
///
/// SwiftUI ships with the SDK, so no manifest can forbid importing it. The
/// guard is `Scripts/check-layers.sh`, and it is the reason this is a rule with
/// teeth rather than an intention.
///
/// ## Why it does not see the design system either
///
/// A presenter that names a colour or a font has started designing. It names
/// **meanings** — `Icon.offline`, not `"wifi.slash"` — and the view layer maps
/// them. That is what makes these types testable without a renderer, and what
/// would make a second front end possible without touching them.
let package = Package(
  name: "Presentation",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Presentation", targets: ["Presentation"])],
  dependencies: [
    .package(path: "../Domain"),
  ],
  targets: [
    .target(
      name: "Presentation",
      dependencies: [.product(name: "Domain", package: "Domain")],
      swiftSettings: .strict
    ),
    .testTarget(name: "PresentationTests", dependencies: ["Presentation"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
