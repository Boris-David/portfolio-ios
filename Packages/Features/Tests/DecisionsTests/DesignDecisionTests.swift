import Domain
import Localization
import Testing

@testable import Decisions

/// A decision declares an identity; every sentence it shows is read from the
/// feature's catalogue. These tests hold that contract.
///
/// The failure they guard against is silent: a key the catalogue does not carry
/// comes back **as the key**, and `decision.role` renders on screen looking
/// almost like a label. Nothing throws, nothing warns.
struct DesignDecisionTests {
  private static let catalogue = TextCatalogue(bundle: .module, table: "Localizable")

  private let full = DesignDecision(
    id: "probe.full",
    component: "NavigationStack",
    in: DesignDecisionTests.catalogue
  )

  /// A decision whose catalogue carries no pitfall and no ruled-out candidate.
  private let spare = DesignDecision(
    id: "probe.spare",
    component: "Divider",
    in: DesignDecisionTests.catalogue
  )

  @Test("reads every field in the language asked for")
  func readsPerLanguage() {
    #expect(full.role(.french) == "Porte la pile.")
    #expect(full.role(.english) == "Holds the stack.")
    #expect(full.rationale(.french) == "Parce que.")
    #expect(full.whenToUse(.english) == "Always.")
  }

  @Test("carries a pitfall only when the catalogue has one")
  func pitfallFollowsTheCatalogue() {
    #expect(full.pitfall(.french) == "Attention.")
    #expect(spare.pitfall(.french) == nil)
  }

  /// The count of ruled-out candidates is **not** declared in Swift: a second
  /// source for it would have been free to disagree with the catalogue. It is
  /// read by walking until the catalogue stops offering one.
  @Test("reads as many ruled-out candidates as the catalogue offers")
  func readsRuledOutCandidates() {
    let candidates = full.rejected(.english)
    #expect(candidates.count == 2)
    #expect(candidates.first?.name == "Other")
    #expect(candidates.first?.because == "no")
    #expect(candidates.last?.name == "Third")
    #expect(spare.rejected(.english).isEmpty)
  }

  /// A component's name is a technical identifier: it is not translated, and
  /// that is deliberate. `NavigationStack` is called `NavigationStack`
  /// everywhere — so it is the one string a decision still carries in Swift.
  @Test("does not translate the component's name")
  func componentIsNotTranslated() {
    #expect(full.component == "NavigationStack")
  }

  /// No field ever comes back as its own key. That is what a missing
  /// translation looks like, and it is the whole reason the guard exists.
  @Test("never renders a key", arguments: [Language.french, .english])
  func neverRendersAKey(language: Language) {
    #expect(!full.role(language).hasPrefix("probe."))
    #expect(!full.rationale(language).hasPrefix("probe."))
    #expect(!full.whenToUse(language).hasPrefix("probe."))
  }

  /// Identity is the id, because the rest is read from a catalogue: two
  /// decisions with the same id would show the same text.
  @Test("is identified by its id")
  func identity() {
    #expect(full != spare)
    #expect(full == DesignDecision(id: "probe.full", component: "Other", in: Self.catalogue))
  }
}
