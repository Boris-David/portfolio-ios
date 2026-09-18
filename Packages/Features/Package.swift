// swift-tools-version: 6.2
import PackageDescription

/// The screens — and the exact list of things a screen is allowed to know.
///
/// ## What this manifest forbids, by omission
///
/// Three names are missing from `dependencies:`, and their absence is the
/// design: `Networking`, `Core`, `Data`. A screen that writes
/// `import Networking` does not get a review comment, it gets "no such module".
/// Dependency inversion held by the resolver rather than by vigilance.
///
/// A screen talks to a **port** — `PortfolioReading`, `ResumeReading` — through
/// the store that `Presentation` owns, and has no way of knowing whether the
/// answer came from the network, the disk cache or the bundled seed. That
/// decision belongs to `Data`; choosing the implementation belongs to
/// `Composition`.
///
/// ## What a target here is for
///
/// Views, and only views. Everything a screen *decides* — its phase, the
/// sentence an error becomes, the shape of a date, where a tap navigates — was
/// moved to `Presentation` and is tested without a renderer. What is left
/// renders: `PhaseView`, `FailureView`, `RichTextView`, the screens themselves.
///
/// ## Why the screens share one package instead of taking one each
///
/// Because `package` visibility only means something inside a package. Six
/// packages of one target each would leave two useful levels, `internal` and
/// `public`, and every type shared between two screens would have to be
/// `public` — visible to the application, to a future widget, to anything that
/// links them. Here `FeatureKit` exposes to its siblings what the app has no
/// business seeing.
///
/// The boundary that matters — screens against infrastructure — is a package
/// boundary. The boundary between two screens is a target boundary, and the
/// architecture tests refuse the edges the compiler would allow.
let package = Package(
  name: "Features",
  // The language the catalogues are written in. Which languages are
  // *supported* is not stated anywhere in Swift — it is whatever the compiled
  // catalogues turn out to contain.
  defaultLocalization: "fr",
  platforms: [.iOS(.v18)],
  products: [
    // One product carrying every screen module. The application imports
    // `FeatureProfile`, `FeatureWork` and the rest by module name; the product
    // is what makes them reachable, and grouping them says the features layer
    // is taken as a whole or not at all.
    .library(
      name: "Features",
      targets: [
        "ViewKit",
        "Decisions",
        "FeatureKit",
        "FeatureProfile",
        "FeatureWork",
        "FeatureJourney",
        "FeatureResume",
        "FeatureEngineering",
        "FeatureContact",
        "FeatureSettings",
        "FeatureArchitecture",
      ]
    ),
  ],
  dependencies: [
    .package(path: "../Domain"),
    .package(path: "../Presentation"),
    .package(path: "../DesignSystem"),

    // The components, and the only package that knows Lottie, Textual and
    // PDFKit exist. No screen in here may name a rendering library: it asks
    // `CoreUI` for a `MarkdownText`, a `LottieAnimation`, a `PDFPreview`.
    //
    // That is not a review rule — this manifest does not declare Textual, so
    // `import Textual` in a screen answers "no such module".
    .package(path: "../CoreUI"),

    // Reading a string catalogue in the language **on screen**. Declared here
    // and, deliberately, **not** in `Presentation`: resolving a key is a
    // rendering concern. A presenter deals in values and keys, never in
    // sentences — which is what keeps it testable without a language.
    //
    // It is a package of its own rather than a corner of `Core` because `Core`
    // also holds the file store and the connectivity reader, and no screen may
    // reach those. Interface segregation, held by this line.
    .package(path: "../Localization"),
  ],
  targets: [
    // ─────────────────────────────────────────────────────────────────────
    // The three shared modules, in a straight line. Each one names what it is
    // for, and each one is below the next: `ViewKit` knows nothing of
    // annotations, `Decisions` knows nothing of navigation.
    // ─────────────────────────────────────────────────────────────────────

    // The SwiftUI vocabulary every screen shares: the content-language
    // environment, the chrome reader, the phase and failure renderers, and the
    // single place where a presentation `Icon` becomes an SF Symbol.
    //
    // It is the floor of the view layer. Nothing here knows what a screen is.
    .target(
      name: "ViewKit",
      dependencies: [
        .product(name: "Domain", package: "Domain"),
        .product(name: "Presentation", package: "Presentation"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "CoreUI", package: "CoreUI"),
        .product(name: "Localization", package: "Localization"),
      ],
      // The content catalogue: operator logos and product screenshots, named by
      // the public slug the API serves. They live with the layer that draws
      // them rather than in the app target, which should hold only what makes
      // it an app.
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),

    // Decisions: the annotation overlay and its rendering.
    //
    // Separate from the design system because it is a **feature of this app**,
    // not a visual primitive; separate from the screens because every screen
    // annotates itself.
    .target(
      name: "Decisions",
      dependencies: [
        .product(name: "Domain", package: "Domain"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "CoreUI", package: "CoreUI"),
        .product(name: "Localization", package: "Localization"),
        "ViewKit",
      ],
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),

    // The scaffolding a screen is mounted in: the navigation stack, the
    // injected route and sheet resolution, the annotation layer applied once
    // for every tab rather than copied into each.
    .target(
      name: "FeatureKit",
      dependencies: ["ViewKit", "Decisions"],
      path: "Sources/Features/Kit",
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),

    // The screens. Target names are what appear in `import` statements and in
    // compiler diagnostics, so they keep the `Feature` prefix; their sources
    // live under `Sources/Features/`, because a flat list of directories stops
    // saying anything about the shape of the project. The explicit `path:` is
    // what lets the two differ.
    .target(name: "FeatureProfile", dependencies: ["FeatureKit"], path: "Sources/Features/Profile", resources: [.process("Resources")], swiftSettings: .strict),
    .target(name: "FeatureWork", dependencies: ["FeatureKit"], path: "Sources/Features/Work", resources: [.process("Resources")], swiftSettings: .strict),
    .target(name: "FeatureJourney", dependencies: ["FeatureKit"], path: "Sources/Features/Journey", resources: [.process("Resources")], swiftSettings: .strict),
    .target(name: "FeatureResume", dependencies: ["FeatureKit"], path: "Sources/Features/Resume", resources: [.process("Resources")], swiftSettings: .strict),
    .target(name: "FeatureEngineering", dependencies: ["FeatureKit"], path: "Sources/Features/Engineering", swiftSettings: .strict),
    .target(name: "FeatureContact", dependencies: ["FeatureKit"], path: "Sources/Features/Contact", swiftSettings: .strict),
    .target(name: "FeatureSettings", dependencies: ["FeatureKit"], path: "Sources/Features/Settings", resources: [.process("Resources")], swiftSettings: .strict),
    .target(name: "FeatureArchitecture", dependencies: ["FeatureKit"], path: "Sources/Features/Architecture", resources: [.process("Resources")], swiftSettings: .strict),

    .testTarget(name: "ViewKitTests", dependencies: ["ViewKit"], swiftSettings: .strict),
    .testTarget(
      name: "DecisionsTests",
      dependencies: ["Decisions"],
      // A probe catalogue. What is under test is a **catalogue lookup**, and a
      // hand-built double would have proved that the double works.
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
