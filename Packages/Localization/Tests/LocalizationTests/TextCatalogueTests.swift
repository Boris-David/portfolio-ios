import Foundation
import Testing

@testable import Localization

/// The claim under test is narrow and load-bearing: **the language on screen is
/// the one asked for, not the one the device prefers.**
///
/// It deserves a suite because the failure it guards against is silent. Nothing
/// throws when a lookup falls back to the device's language — the label simply
/// comes out in the wrong one, beside content in the right one, and only a
/// reader notices.
@Suite("TextCatalogue")
struct TextCatalogueTests {
  private let catalogue = TextCatalogue(bundle: .module, table: "Localizable")

  @Test("reports the languages the catalogue compiled to, and nothing declares them")
  func reportsItsLanguages() {
    #expect(catalogue.languages == ["en", "fr"])
  }

  @Test("serves the language it is asked for, in both directions")
  func servesTheLanguageAsked() {
    #expect(catalogue("probe.greeting", in: "fr") == "Bonjour")
    #expect(catalogue("probe.greeting", in: "en") == "Hello")
  }

  /// The regression that motivated the type. The process runs under one locale;
  /// the catalogue is asked for the other. A lookup honouring the device would
  /// return the same string for both, and this fails on the first line — which
  /// is the point.
  @Test("ignores the device's preference")
  func ignoresTheDevicePreference() {
    let devicePreference = Bundle.main.preferredLocalizations.first ?? "en"
    let other = devicePreference.hasPrefix("fr") ? "en" : "fr"
    let expected = other == "fr" ? "Bonjour" : "Hello"

    #expect(catalogue("probe.greeting", in: other) == expected)
  }

  /// The defect this replaced: `"\(count) chantiers"`, written by hand, reads
  /// "1 chantiers".
  @Test("varies by plural, per language", arguments: [
    (1, "fr", "1 chantier"),
    (2, "fr", "2 chantiers"),
    (1, "en", "1 workstream"),
    (2, "en", "2 workstreams"),
  ])
  func variesByPlural(count: Int, language: String, expected: String) {
    #expect(catalogue("probe.workstreams", in: language, count: count) == expected)
  }

  /// French puts zero in the singular, English in the plural. Hand-written code
  /// gets this wrong by default; the rule belongs to the language, and naming
  /// the language is what fetches it.
  @Test("applies the asked language's plural rule, not the device's")
  func pluralRuleFollowsTheLanguage() {
    #expect(catalogue("probe.workstreams", in: "fr", count: 0) == "0 chantier")
    #expect(catalogue("probe.workstreams", in: "en", count: 0) == "0 workstreams")
  }

  /// What replaces the compile error a two-field struct used to give. The guard
  /// and the per-catalogue suites are built on this answer.
  @Test("reports a key it does not carry")
  func reportsAMissingKey() {
    #expect(catalogue.contains("probe.greeting", in: "fr"))
    #expect(catalogue.contains("probe.greeting", in: "en"))
    #expect(!catalogue.contains("probe.absent", in: "fr"))
  }

  /// An unknown code must not silently become the device's language — that is
  /// the same defect by another door. It falls back to the catalogue's source
  /// language, which is a deliberate, testable answer.
  @Test("an unknown language code falls back to the source language")
  func unknownCodeFallsBackToSource() {
    #expect(catalogue("probe.greeting", in: "de") == "Bonjour")
  }
}
