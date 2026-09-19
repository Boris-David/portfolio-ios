import Domain
import Foundation
import Testing

@testable import Data

/// The deep dives — the essays behind the three topics on the profile.
///
/// ## Why this suite exists
///
/// The route to these screens existed, the API served the content, and **no
/// screen had ever been written**. Touching a topic opened a black page with a
/// back button. Nothing failed: the resolver's `default:` returned an empty
/// view, and an empty view is indistinguishable from a screen that has nothing
/// to say.
///
/// The compiler now refuses an unresolved route. This refuses the other half —
/// content that arrives and is never read.
@Suite("Deep dives")
struct DeepDiveMappingTests {
  private static func portfolio(_ language: Language) throws -> Portfolio {
    let url = try #require(Bundle.module.url(
      forResource: "portfolio-\(language.rawValue)", withExtension: "json"
    ))
    let envelope = try JSONDecoder().decode(
      PortfolioEnvelopeDTO.self, from: Data(contentsOf: url)
    )
    return try PortfolioMapper.portfolio(from: envelope.data)
  }

  @Test("reads a dive for every expertise topic", arguments: Language.allCases)
  func everyTopicHasADive(_ language: Language) throws {
    let portfolio = try Self.portfolio(language)

    #expect(!portfolio.expertise.isEmpty, "no topic at all — this suite would pass on nothing")
    for topic in portfolio.expertise {
      #expect(
        portfolio.deepDive(for: topic.id) != nil,
        "\(topic.title) is tappable on the profile and would open a page with nothing under its title"
      )
    }
  }

  @Test("carries a lede and at least one section", arguments: Language.allCases)
  func divesAreNotEmpty(_ language: Language) throws {
    for dive in try Self.portfolio(language).deepDives {
      #expect(!dive.lede.plain.isEmpty, "\(dive.expertise) opens on nothing")
      #expect(!dive.sections.isEmpty, "\(dive.expertise) has no section")
      for section in dive.sections {
        #expect(!section.heading.isEmpty)
        #expect(!section.blocks.isEmpty, "\(dive.expertise)/\(section.slug) is an empty heading")
      }
    }
  }

  /// A dive points at the chapter that proves it. A pointer to a case study the
  /// portfolio does not carry would push a screen that says "content not there"
  /// — from a link the reader had every reason to trust.
  @Test("points only at case studies the portfolio carries", arguments: Language.allCases)
  func evidencePointsSomewhere(_ language: Language) throws {
    let portfolio = try Self.portfolio(language)
    let slugs = Set(portfolio.caseStudies.map(\.slug))

    for dive in portfolio.deepDives {
      guard let evidence = dive.evidence else { continue }
      #expect(
        slugs.contains(evidence.caseStudy),
        "\(dive.expertise) cites “\(evidence.caseStudy)”, which is not published"
      )
    }
  }

  /// The two languages describe the same portfolio. A dive present in one and
  /// absent in the other is a screen that works until the reader switches.
  @Test("publishes the same dives in both languages")
  func bothLanguagesAgree() throws {
    let french = try Self.portfolio(.french).deepDives.map(\.expertise).sorted()
    let english = try Self.portfolio(.english).deepDives.map(\.expertise).sorted()
    #expect(french == english)
  }
}
