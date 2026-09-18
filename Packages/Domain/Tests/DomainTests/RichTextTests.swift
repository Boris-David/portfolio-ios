import Testing
@testable import Domain

struct RichTextTests {
  @Test("le texte nu concatène les segments sans perdre les espaces")
  func plainKeepsSpacing() {
    let text = RichText(spans: [
      .init(text: "Je développe la ", emphasis: .plain),
      .init(text: "billettique mobile", emphasis: .strong),
      .init(text: " chez Instant System.", emphasis: .plain),
    ])
    #expect(text.plain == "Je développe la billettique mobile chez Instant System.")
  }

  @Test("un texte sans segment est vide")
  func emptyWhenNoSpans() {
    #expect(RichText(spans: []).isEmpty)
  }
}

struct YearMonthTests {
  @Test("l'ordre chronologique est celui qu'on attend")
  func ordering() {
    #expect(YearMonth(year: 2020, month: 10) < YearMonth(year: 2021, month: 1))
    #expect(YearMonth(year: 2023, month: 4) < YearMonth(year: 2023, month: 5))
  }

  /// A bare year counts as January: that is what lets certifications dated
  /// "2025" be sorted alongside experiences dated "2025-03".
  @Test("une année sans mois se compare comme janvier")
  func yearOnlyIsJanuary() {
    #expect(YearMonth(year: 2025) < YearMonth(year: 2025, month: 2))
    #expect(!(YearMonth(year: 2025, month: 1) < YearMonth(year: 2025)))
  }
}

struct PortfolioSnapshotTests {
  @Test("un instantané venu du réseau n'est pas périmé")
  func networkIsFresh() {
    let snapshot = PortfolioSnapshot(
      portfolio: .fixture,
      contentVersion: "v1",
      origin: .network
    )
    #expect(!snapshot.isStale)
  }

  @Test("tout ce qui ne vient pas du réseau est périmé", arguments: [
    ContentOrigin.cache(storedAt: .distantPast),
    ContentOrigin.bundledSeed(builtAt: .distantPast),
  ])
  func localIsStale(_ origin: ContentOrigin) {
    let snapshot = PortfolioSnapshot(portfolio: .fixture, contentVersion: "v1", origin: origin)
    #expect(snapshot.isStale)
  }
}

extension Portfolio {
  /// The smallest possible portfolio — this module's tests say nothing about
  /// content, only about structure.
  static let fixture = Portfolio(
    profile: Profile(
      name: .init(display: "A.", full: "A."),
      headline: "h", availability: "a", location: "l", remote: "r", languages: "fr",
      summary: [], showcase: .init(media: .init(id: "m", alt: "", caption: ""), caseStudySlug: nil),
      contact: .init(email: "a@b.c", title: "t", body: "b", links: []),
      footer: .init(role: "r", location: "l")
    ),
    metrics: [], sections: [], caseStudies: [],
    apps: AppCatalogue(verifiedOn: "2026-01-01", items: []),
    expertise: [],
    architectures: ArchitectureDossier(
      verifiedOn: "2026-01-01", intro: "i", patterns: [], projects: []
    ),
    experience: [],
    background: Background(education: [], certifications: [], openProjects: []),
    skills: []
  )
}
