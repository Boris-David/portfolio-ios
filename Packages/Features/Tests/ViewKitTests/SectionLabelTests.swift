import Localization
import Presentation
import Testing

@testable import ViewKit

/// Every tab must be named, in every language the catalogue carries.
///
/// The failure this guards against is silent: a key the catalogue does not hold
/// comes back **as the key**, so a missing translation ships as a tab reading
/// `interface.tabWork` rather than as a crash or a warning.
///
/// It lives here and not with `Presentation` because a title is read from a
/// catalogue, and that layer no longer has one — which is the whole point of
/// having moved it.
@Suite("Section labels")
struct SectionLabelTests {
  private let catalogue = TextCatalogue(bundle: .module, table: "Localizable")

  @Test("names every section in every language the catalogue carries",
        arguments: AppSection.allCases)
  func everySectionIsNamed(_ section: AppSection) {
    for language in catalogue.languages {
      let title = catalogue(section.titleKey.identifier, in: language)
      #expect(!title.isEmpty)
      #expect(title != section.titleKey.identifier, "\(section) is untranslated in \(language)")
    }
  }

  /// Two tabs sharing a word would be two tabs a reader cannot tell apart.
  @Test("gives each section a distinct name")
  func sectionNamesAreDistinct() {
    for language in catalogue.languages {
      let titles = AppSection.allCases.map { catalogue($0.titleKey.identifier, in: language) }
      #expect(Set(titles).count == titles.count, "two sections share a name in \(language)")
    }
  }
}
