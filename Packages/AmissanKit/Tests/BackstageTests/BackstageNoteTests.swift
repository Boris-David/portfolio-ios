import Domain
import Testing
@testable import Backstage

/// Les annotations sont du **contenu**, et ce contenu est bilingue.
///
/// Une traduction oubliée ne casse rien : elle affiche du français dans une
/// interface anglaise, ce qui se remarque au pire moment. D'où une garde
/// structurelle plutôt qu'une relecture.
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

  /// Le nom du composant est un identifiant technique : il ne se traduit pas,
  /// et c'est voulu. `NavigationStack` s'appelle `NavigationStack` partout.
  @Test("le nom du composant n'est pas une chaîne traduisible")
  func componentIsNotTranslated() {
    #expect(sample.component == "NavigationStack")
  }
}
