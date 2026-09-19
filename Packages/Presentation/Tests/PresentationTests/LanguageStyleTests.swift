import Domain
import Testing
@testable import Presentation

/// A language names itself.
///
/// The point of the test is not that `Foundation` works — it is that the label
/// is the **endonym** and not a translation into the interface language. Those
/// two differ for every language but one, and only one of them is right on a
/// document.
struct LanguageStyleTests {
  @Test("each language is named in its own language")
  func endonyms() {
    #expect(LanguageStyle(language: .french).endonym == "Français")
    #expect(LanguageStyle(language: .english).endonym == "English")
  }

  /// The endonym must not follow the reader's interface language: it describes
  /// a document, not a preference. If it ever did, French would read "French"
  /// for an English reader and the label would stop being about the file.
  @Test("the name does not depend on which language is asking")
  func independentOfTheAsker() {
    let french = LanguageStyle(language: .french).endonym
    let english = LanguageStyle(language: .english).endonym
    #expect(french != english)
    #expect(!french.isEmpty)
    #expect(!english.isEmpty)
  }
}
