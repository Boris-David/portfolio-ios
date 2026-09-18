import Domain
import Testing
@testable import Data

/// The boundary where a string becomes a domain value.
///
/// An unexpected value **throws** — it does not fall back to a default. An
/// unknown role filed under "features" would put an app in the wrong grid, and
/// that is the kind of mistake you only notice in an interview.
struct MappingTests {
  @Test("lit une date année-mois", arguments: [
    ("2023-05", 2023, 5), ("2020-10", 2020, 10),
  ])
  func yearMonth(_ raw: String, _ year: Int, _ month: Int) throws {
    let value = try PortfolioMapping.yearMonth(raw, at: "test")
    #expect(value == YearMonth(year: year, month: month))
  }

  @Test("lit une année seule")
  func yearOnly() throws {
    #expect(try PortfolioMapping.yearMonth("2025", at: "test") == YearMonth(year: 2025))
  }

  @Test("refuse une date illisible, en nommant le champ", arguments: [
    "2023-13", "23-05", "", "2023-", "2023-05-01", "hier",
  ])
  func refusesBadDate(_ raw: String) {
    #expect(throws: MappingError.self) {
      try PortfolioMapping.yearMonth(raw, at: "experience[x].start")
    }
  }

  @Test("refuse une URL qui n'est pas en https", arguments: [
    "http://exemple.fr", "javascript:alert(1)", "pas une url", "",
  ])
  func refusesInsecureURL(_ raw: String) {
    #expect(throws: MappingError.self) {
      try PortfolioMapping.url(raw, at: "profile.contact.links[github].url")
    }
  }

  @Test("accepte une URL https")
  func acceptsHTTPS() throws {
    let url = try PortfolioMapping.url("https://amissan.dev", at: "test")
    #expect(url == "https://amissan.dev")
  }

  /// An unknown emphasis style falls back to plain: getting the weight wrong
  /// changes nothing about the meaning, and failing the whole payload over it
  /// would be out of proportion. The opposite of an application role.
  @Test("un style de texte inconnu ne fait pas échouer la charge")
  func unknownEmphasisIsLenient() {
    let text = PortfolioMapping.richText([
      SpanDTO(text: "a", style: "strong"),
      SpanDTO(text: "b", style: "inconnu"),
      SpanDTO(text: "c", style: "code"),
    ])
    #expect(text.spans.map(\.emphasis) == [.strong, .plain, .code])
  }
}
