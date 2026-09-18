// swift-tools-version: 6.2
import PackageDescription

/// The cross-cutting mechanics — and **no knowledge of the portfolio**.
///
/// ## What is allowed in, and what keeps it out
///
/// A `Core` package is a junk drawer waiting to happen: everybody depends on it,
/// so everything put here becomes global — which is the opposite of layering.
/// One rule, written down, is the only thing that prevents it:
///
/// > Something enters `Core` when it **(a)** serves at least two layers,
/// > **(b)** knows nothing about the portfolio, and **(c)** could ship in
/// > another application without changing a line.
///
/// Every current inhabitant passes all three: a clock, a key-value store, a file
/// store, a connectivity monitor, an event bus. None of them has heard of a
/// case study.
///
/// ## Why it absorbed `Persistence`
///
/// Because two abstractions over storage was exactly the duplication this
/// package exists to end. `FileStore` keeps bulky content the system may purge;
/// `KeyValueStore` keeps preferences that must never be purged. Same mechanism,
/// opposite contracts — but one home.
///
/// ## `dependencies: []`
///
/// Not an oversight. `Core` is depended upon by everything, so a dependency here
/// is a dependency everywhere. The empty array is what stops `Core` from
/// becoming a back door into the domain.
let package = Package(
  name: "Core",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Core", targets: ["Core"])],
  dependencies: [],
  targets: [
    .target(name: "Core", swiftSettings: .strict),
    .testTarget(name: "CoreTests", dependencies: ["Core"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
