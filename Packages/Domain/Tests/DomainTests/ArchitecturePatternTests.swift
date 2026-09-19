import Testing
@testable import Domain

/// The comparison is only a comparison if every pattern answers every question.
///
/// The screen walks `Criterion.allCases` rather than writing one row per
/// question by hand. That is what makes a new question appear in all four
/// columns at once — and what makes a wrong wiring here silent: the row would
/// render, filled with the wrong field. Hence this suite.
struct ArchitecturePatternTests {
  @Test("chaque question rend son propre champ")
  func eachCriterionReturnsItsOwnField() {
    let pattern = ArchitecturePattern(
      id: .clean,
      name: "Clean",
      separates: "separates",
      buys: "buys",
      costs: "costs",
      chooseWhen: "choose",
      breaksWhen: "breaks"
    )

    #expect(pattern.answer(to: .buys).plain == "buys")
    #expect(pattern.answer(to: .costs).plain == "costs")
    #expect(pattern.answer(to: .chooseWhen).plain == "choose")
    #expect(pattern.answer(to: .breaksWhen).plain == "breaks")
  }

  /// Four questions, and the same four for everyone. A pattern that could skip
  /// one would turn the table into four paragraphs standing side by side.
  @Test("les quatre questions de la comparaison")
  func theComparisonAsksFourQuestions() {
    #expect(ArchitecturePattern.Criterion.allCases.count == 4)
  }

  /// The identifiers are the API's closed set, and they are what a codebase
  /// points at. Spelling one differently here would not fail to compile — it
  /// would fail to resolve, at runtime, on a payload that is perfectly valid.
  @Test("les identifiants sont ceux que sert la source", arguments: [
    (ArchitecturePattern.Identifier.mvc, "mvc"),
    (.mvp, "mvp"),
    (.mvvm, "mvvm"),
    (.clean, "clean"),
  ])
  func identifiersMatchTheSource(_ identifier: ArchitecturePattern.Identifier, _ raw: String) {
    #expect(identifier.rawValue == raw)
  }
}
