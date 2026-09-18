// swift-tools-version: 6.2
import PackageDescription

/// Bytes on disk, and no knowledge of what they mean.
///
/// Like `Networking`, it does not depend on the domain: `FileStore` writes
/// `Data` under a key and gives it back with the date it was written. It has
/// never heard of a portfolio.
///
/// ## Why not SwiftData
///
/// SwiftData answers a question this app does not ask. There is no local
/// mutation, no relational query, no partial synchronisation: the content is a
/// document the source owns and the app displays. What is needed is "keep these
/// bytes, give them back with their date" — and a store that can do far more is
/// a store whose migrations, threading model and failure modes all have to be
/// understood before the first line ships.
let package = Package(
  name: "Persistence",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Persistence", targets: ["Persistence"])],
  dependencies: [],
  targets: [
    .target(name: "Persistence", swiftSettings: .strict),
    .testTarget(name: "PersistenceTests", dependencies: ["Persistence"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
