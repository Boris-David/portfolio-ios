import Testing
@testable import Presentation

/// The invariant that used to be held by having two types.
///
/// `Sheet` and `FullScreenCover` made "the résumé is not a sheet" a compile
/// error, which is stronger than a test — and which said *that* it was true
/// without ever saying why, and which cost the app a second presentation anchor
/// that shipped without its environment.
///
/// One type, and the invariant moves here. A reader who wonders why the résumé
/// takes the whole screen gets an answer; a change that makes it a sheet gets a
/// failing test instead of a review comment.
struct ModalTests {
  @Test("the résumé takes the whole screen; the two short tasks do not")
  func styles() {
    #expect(Modal.resume.style == .fullScreen)
    #expect(Modal.contact.style == .sheet)
    #expect(Modal.settings.style == .sheet)
  }

  @Test("every modal has exactly one style, and both styles are used")
  func everyModalIsPresentable() {
    let styles = Set(Modal.allCases.map(\.style))
    #expect(styles == [.sheet, .fullScreen])
  }

  /// `Identifiable` decides whether SwiftUI rebuilds the presented screen or
  /// keeps it. Two modals sharing an id would let one replace the other with no
  /// transition and no redraw.
  @Test("each modal identifies itself uniquely")
  func identifiers() {
    #expect(Set(Modal.allCases.map(\.id)).count == Modal.allCases.count)
  }
}

/// Tapping the tab you are already on.
///
/// The whole point of counting rather than flagging: the gesture repeats, and
/// the second tap is the one that takes an already-rooted section to the top.
/// A `Bool` would have made that tap invisible.
@MainActor
struct SectionReselectionTests {
  @Test("a section nobody re-tapped counts zero")
  func startsAtZero() {
    #expect(SectionReselection().count(.profile) == 0)
  }

  @Test("each tap on the same section is a separate event")
  func repeatedTapsAreDistinct() {
    let reselection = SectionReselection()
    reselection.record(.work)
    reselection.record(.work)
    #expect(reselection.count(.work) == 2)
  }

  @Test("sections are counted apart")
  func sectionsDoNotShareACount() {
    let reselection = SectionReselection()
    reselection.record(.work)
    #expect(reselection.count(.work) == 1)
    #expect(reselection.count(.journey) == 0)
  }
}
