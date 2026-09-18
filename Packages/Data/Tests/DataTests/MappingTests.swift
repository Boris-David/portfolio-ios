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
    let value = try PortfolioMapper.yearMonth(raw, at: "test")
    #expect(value == YearMonth(year: year, month: month))
  }

  @Test("lit une année seule")
  func yearOnly() throws {
    #expect(try PortfolioMapper.yearMonth("2025", at: "test") == YearMonth(year: 2025))
  }

  @Test("refuse une date illisible, en nommant le champ", arguments: [
    "2023-13", "23-05", "", "2023-", "2023-05-01", "hier",
  ])
  func refusesBadDate(_ raw: String) {
    #expect(throws: MappingError.self) {
      try PortfolioMapper.yearMonth(raw, at: "experience[x].start")
    }
  }

  @Test("refuse une URL qui n'est pas en https", arguments: [
    "http://exemple.fr", "javascript:alert(1)", "pas une url", "",
  ])
  func refusesInsecureURL(_ raw: String) {
    #expect(throws: MappingError.self) {
      try PortfolioMapper.url(raw, at: "profile.contact.links[github].url")
    }
  }

  @Test("accepte une URL https")
  func acceptsHTTPS() throws {
    let url = try PortfolioMapper.url("https://amissan.dev", at: "test")
    #expect(url == "https://amissan.dev")
  }

  /// An unknown emphasis style falls back to plain: getting the weight wrong
  /// changes nothing about the meaning, and failing the whole payload over it
  /// would be out of proportion. The opposite of an application role.
  @Test("un style de texte inconnu ne fait pas échouer la charge")
  func unknownEmphasisIsLenient() {
    let text = PortfolioMapper.richText([
      SpanDTO(text: "a", style: "strong"),
      SpanDTO(text: "b", style: "inconnu"),
      SpanDTO(text: "c", style: "code"),
    ])
    #expect(text.spans.map(\.emphasis) == [.strong, .plain, .code])
  }

  // ── Architectures ──────────────────────────────────────────────────────

  /// The comparison has one column per pattern. A fifth identifier has no cell
  /// to go in, so accepting it would mean dropping a column — and the table
  /// would still look complete.
  @Test("refuse un motif hors de l'ensemble fermé, en nommant le champ")
  func refusesUnknownPattern() {
    let study = ArchitectureStudyDTO(
      verifiedOn: "2026-09-18",
      intro: [SpanDTO(text: "i", style: "plain")],
      patterns: [.stub(id: "viper")],
      projects: []
    )

    #expect {
      try PortfolioMapper.architectureStudy(from: study)
    } throws: { error in
      error as? MappingError == MappingError(
        path: "architectures.patterns[viper].id",
        reason: .unknownValue("viper")
      )
    }
  }

  /// A codebase points at a pattern instead of restating it. A pointer that
  /// leads nowhere is refused rather than dropped: a codebase shown without the
  /// pattern it illustrates says nothing.
  @Test("refuse un projet qui pointe vers un motif absent du study")
  func refusesDanglingPatternReference() {
    let study = ArchitectureStudyDTO(
      verifiedOn: "2026-09-18",
      intro: [SpanDTO(text: "i", style: "plain")],
      patterns: [.stub(id: "mvvm")],
      projects: [.stub(id: "a-codebase", pattern: "clean")]
    )

    #expect {
      try PortfolioMapper.architectureStudy(from: study)
    } throws: { error in
      error as? MappingError == MappingError(
        path: "architectures.projects[a-codebase].pattern",
        reason: .unknownValue("clean")
      )
    }
  }

  /// The reference is followed once, at the crossing, so that nothing
  /// downstream ever holds a project whose pattern might be missing.
  @Test("résout le motif de chaque base de code")
  func resolvesEachProjectsPattern() throws {
    let study = try PortfolioMapper.architectureStudy(from: ArchitectureStudyDTO(
      verifiedOn: "2026-09-18",
      intro: [SpanDTO(text: "i", style: "plain")],
      patterns: [.stub(id: "mvvm"), .stub(id: "clean")],
      projects: [.stub(id: "a-codebase", pattern: "clean")]
    ))

    let project = try #require(study.projects.first)
    #expect(project.pattern.id == .clean)
    #expect(project.evidence == [ArchitectureEvidence(symbol: "UseCase", count: 677)])
    #expect(study.verifiedOn == "2026-09-18")
  }
}

// ── Fixtures ─────────────────────────────────────────────────────────────

private extension ArchitecturePatternDTO {
  /// A pattern whose only interesting field is the identifier — which is the
  /// only one the mapper has a decision to make about.
  static func stub(id: String) -> ArchitecturePatternDTO {
    ArchitecturePatternDTO(
      id: id,
      name: id,
      separates: "separates",
      buys: [SpanDTO(text: "buys", style: "plain")],
      costs: [SpanDTO(text: "costs", style: "plain")],
      chooseWhen: [SpanDTO(text: "choose", style: "plain")],
      breaksWhen: [SpanDTO(text: "breaks", style: "plain")]
    )
  }
}

private extension ProjectArchitectureDTO {
  static func stub(id: String, pattern: String) -> ProjectArchitectureDTO {
    ProjectArchitectureDTO(
      id: id,
      name: id,
      context: "context",
      pattern: pattern,
      stack: ["Swift"],
      evidence: [ArchitectureEvidenceDTO(symbol: "UseCase", count: 677)],
      reading: [SpanDTO(text: "reading", style: "plain")]
    )
  }
}
