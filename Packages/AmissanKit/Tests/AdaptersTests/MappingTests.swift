import Domain
import Testing
@testable import Adapters

/// La frontière où une chaîne devient une valeur du domaine.
///
/// Une valeur inattendue **lève** — elle ne se replie pas sur un défaut. Un rôle
/// inconnu rangé en « fonctionnalités » ferait apparaître une application dans
/// la mauvaise grille, et c'est le genre d'erreur qu'on ne voit qu'en entretien.
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

  /// Un style d'emphase inconnu retombe sur « texte » : se tromper de graisse ne
  /// change rien au sens, et faire échouer toute la charge pour ça serait
  /// disproportionné. C'est l'inverse d'un rôle d'application.
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
