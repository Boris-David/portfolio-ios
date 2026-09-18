// swift-tools-version: 6.2
import PackageDescription

/// The data layer: where the content comes from, and what shape it arrives in.
///
/// ## Why it is called `Data` and not `Adapters`
///
/// It was briefly renamed `Adapters`, and that was a category error — corrected
/// on 2026-09-18 by the author, who was right. The two words name different
/// things:
///
/// - **an adapter is a role.** Anything that converts between the application's
///   shape and a technology's shape is one. `URLSessionHTTPClient` is an
///   adapter, in `Networking`. `PortfolioStore` is an adapter too, on the other
///   side, in `Presentation`. Naming *this* package `Adapters` would claim a
///   role it does not own alone;
/// - **the data layer is a concern**, and this package owns all of it: where
///   content is fetched, how it is decoded, when the local copy is used, and
///   what shape crosses into the domain.
///
/// `Domain` holds the port; this package holds the **gateway** that implements
/// it — which is the canonical Clean Architecture word for the object that
/// stands between a use case and a source of data.
///
/// ## Why the DTOs live here and never in the domain
///
/// An entity carrying `CodingKeys` is an entity that let the network dictate its
/// shape. Rename a field on the server and the domain changes — exactly the
/// coupling the layering exists to prevent. Here the rename costs one line in a
/// DTO and nothing else.
///
/// ## What it may depend on
///
/// The domain, and the two technical packages. It is the **only** package that
/// names all three, and that is the visible form of the statement: no screen can
/// reach `Networking` without adding a line to its own manifest, which the
/// architecture tests refuse.
let package = Package(
  name: "Data",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Data", targets: ["Data"])],
  dependencies: [
    .package(path: "../Domain"),
    .package(path: "../Networking"),
    .package(path: "../Core"),
  ],
  targets: [
    .target(
      name: "Data",
      dependencies: [
        .product(name: "Domain", package: "Domain"),
        .product(name: "Networking", package: "Networking"),
        .product(name: "Core", package: "Core"),
      ],
      // The bundled seed — produced from the API by `Scripts/seed.sh`, never
      // written by hand. A hand-written snapshot is a second source of truth.
      resources: [.process("Resources")],
      swiftSettings: .strict
    ),
    .testTarget(
      name: "DataTests",
      dependencies: ["Data"],
      resources: [.process("Fixtures")],
      swiftSettings: .strict
    ),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
