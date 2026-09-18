// swift-tools-version: 6.2
import PackageDescription

/// HTTP, and no knowledge of what it carries.
///
/// This package does not depend on `Domain`, deliberately: nothing here knows
/// what a profile or a case study is. It moves bytes, reads status codes,
/// parses `Content-Disposition`. The same code would serve a weather app.
///
/// ## Why not just `URLSession`
///
/// Because `URLSession` is a concrete type, and a repository that names it can
/// only be tested against a real network or a `URLProtocol` subclass installed
/// process-wide. `HTTPClient` is one protocol with one method: the data layer
/// names the protocol, the composition root names the implementation, and a
/// test hands over three lines of stub.
///
/// ## Why not Alamofire
///
/// The app explains this out loud in its Backstage section, so the short form:
/// Alamofire answered a question `URLSession` used to leave open — request
/// building, retries, multipart. Since `async/await`, the parts still worth
/// having are the few hundred lines in this package, and those lines are
/// readable by the people this repository is written for. A dependency is worth
/// what would be **worse without it**, never what it makes convenient.
let package = Package(
  name: "Networking",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Networking", targets: ["Networking"])],
  dependencies: [],
  targets: [
    .target(name: "Networking", swiftSettings: .strict),
    .testTarget(name: "NetworkingTests", dependencies: ["Networking"], swiftSettings: .strict),
  ],
  swiftLanguageModes: [.v6]
)

extension [SwiftSetting] {
  /// See `Domain/Package.swift` for why `ExistentialAny` is on everywhere.
  static var strict: [SwiftSetting] { [.enableUpcomingFeature("ExistentialAny")] }
}
