import Domain
import Testing
@testable import Backstage

/// Annotations are **content**, and that content is bilingual.
///
/// A forgotten translation breaks nothing: it shows French inside an English
/// interface, which gets noticed at the worst possible moment. Hence a
/// structural guard rather than a proofread.
struct BackstageNoteTests {
  private let sample = BackstageNote(
    id: "test",
    component: "NavigationStack",
    role: Bilingual(fr: "Porte la pile.", en: "Holds the stack."),
    rationale: Bilingual(fr: "Parce que.", en: "Because."),
    rejected: [.init(Bilingual(fr: "Autre", en: "Other"), because: Bilingual(fr: "non", en: "no"))],
    whenToUse: Bilingual(fr: "Toujours.", en: "Always."),
    pitfall: Bilingual(fr: "Attention.", en: "Careful.")
  )

  @Test("rend chaque champ dans la langue demandée")
  func rendersPerLanguage() {
    #expect(sample.role(.french) == "Porte la pile.")
    #expect(sample.role(.english) == "Holds the stack.")
    #expect(sample.rejected[0].because(.english) == "no")
  }

  @Test("un champ traduit dans les deux langues est complet")
  func completeness() {
    #expect(sample.role.isComplete)
    #expect(sample.rationale.isComplete)
    #expect(sample.whenToUse.isComplete)
    #expect(sample.pitfall?.isComplete == true)
  }

  /// A component's name is a technical identifier: it is not translated, and
  /// that is deliberate. `NavigationStack` is called `NavigationStack`
  /// everywhere.
  @Test("le nom du composant n'est pas une chaîne traduisible")
  func componentIsNotTranslated() {
    #expect(sample.component == "NavigationStack")
  }
}
