import Testing
@testable import Decisions

/// The annotation numbers, which used to change under the reader's finger.
///
/// Every test here fails against the old behaviour — the number being the pin's
/// index in whatever set of pins happened to be on screen.
struct DecisionNumberingTests {
  @Test("notes are numbered in the order they are first seen")
  func numbersInReadingOrder() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero", "metrics", "shelf"])
    #expect(numbering.number(of: "hero") == 1)
    #expect(numbering.number(of: "metrics") == 2)
    #expect(numbering.number(of: "shelf") == 3)
  }

  /// The defect itself. A lazy container drops what scrolls off and builds what
  /// scrolls in, so the set shrinks from the top and grows at the bottom. With
  /// positional numbering, `shelf` went from 3 to 1 mid-scroll and badge 1
  /// stopped opening what badge 1 had just opened.
  @Test("a note keeps its number when the ones above it scroll away")
  func scrollingDoesNotRenumber() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero", "metrics", "shelf"])
    numbering.assign(["metrics", "shelf", "expertise"])
    #expect(numbering.number(of: "shelf") == 3)
    #expect(numbering.number(of: "expertise") == 4)
  }

  @Test("scrolling back up finds the same numbers")
  func scrollingBackIsStable() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero", "metrics"])
    numbering.assign(["metrics", "shelf"])
    numbering.assign(["hero", "metrics"])
    #expect(numbering.number(of: "hero") == 1)
    #expect(numbering.number(of: "metrics") == 2)
    #expect(numbering.number(of: "shelf") == 3)
  }

  @Test("a screen with nothing in common starts again at one")
  func aNewScreenStartsAtOne() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero", "metrics", "shelf"])
    numbering.assign(["study.disclosure", "study.gallery"])
    #expect(numbering.number(of: "study.disclosure") == 1)
    #expect(numbering.number(of: "study.gallery") == 2)
    // And the screen left behind is forgotten rather than held for ever.
    #expect(numbering.number(of: "hero") == nil)
  }

  /// The reset must never fire while something numbered is still on screen —
  /// that is the difference between "a new screen" and "a long scroll".
  @Test("one note in common is enough to keep the numbering")
  func oneSurvivorPreventsAReset() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero", "metrics", "shelf"])
    numbering.assign(["shelf", "expertise", "contact"])
    #expect(numbering.number(of: "shelf") == 3)
    #expect(numbering.number(of: "expertise") == 4)
    #expect(numbering.number(of: "contact") == 5)
  }

  /// An empty set is the frame between two screens, not a screen with no
  /// annotations: resetting on it would renumber everything on arrival.
  @Test("an empty pass changes nothing")
  func emptyPassIsIgnored() {
    var numbering = DecisionNumbering()
    numbering.assign(["hero"])
    numbering.assign([])
    #expect(numbering.number(of: "hero") == 1)
  }
}
