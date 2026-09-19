// swift-tools-version: 6.2
import PackageDescription

/// Reading a string catalogue **in a language the caller names**.
///
/// ## Why a package of its own, for one type
///
/// Two layers need it — `Presentation`, which owns the interface labels, and
/// `Features`, where each screen carries its own catalogue. There was already a
/// package for mechanisms shared by several layers, `Core`, and this is not in
/// it.
///
/// Because `Core` also holds the file store, the key-value store and the
/// connectivity reader, and the architecture tests state, as the central
/// invariant, that **no screen may reach the network, the disk or the data
/// layer**. Putting a string reader in `Core` would have bought a small
/// convenience with disk access for every view in the application.
///
/// So the boundary follows the need rather than the filing: a package that
/// offers exactly one capability, to whoever needs exactly that. Interface
/// segregation, held by the manifest instead of by good intentions.
///
/// ## What it deliberately does not know
///
/// Which languages exist. It is handed a bundle and a language **code**; the set
/// of supported languages is whatever the compiled catalogue turns out to
/// contain, and `TextCatalogue.languages` reports it. Nothing here — and nothing
/// above it — enumerates "French" and "English": adding a third language is a
/// catalogue that has one more column, not a type with one more case.
let package = Package(
  name: "Localization",
  // SwiftPM requires a source language for any target carrying localized
  // resources. It names the language the catalogue is **written in**, not a
  // supported set — the supported set is whatever the catalogue compiles to.
  defaultLocalization: "fr",
  platforms: [.iOS(.v18)],
  products: [.library(name: "Localization", targets: ["Localization"])],
  dependencies: [],
  targets: [
    .target(name: "Localization", swiftSettings: .strict),

    // The probe catalogue. This package claims it can read a language the
    // device did not ask for, and that claim is worth exactly what a **really
    // compiled** `.xcstrings` says it is — so the tests carry one.
    .testTarget(
      name: "LocalizationTests",
      dependencies: ["Localization"],
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
