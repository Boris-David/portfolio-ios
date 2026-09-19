import Presentation
import SwiftUI
import Testing
import UIKit
@testable import ViewKit

/// **Every icon must actually exist.**
///
/// An SF Symbol whose name is misspelled does not crash and does not warn: it
/// renders *nothing*. A hole where the icon was, on the one screen nobody opened
/// before shipping. `UIImage(systemName:)` returns `nil` for an unknown name,
/// which is the only way to find out without looking.
///
/// This is the test that pays for the `Icon` enum. Asserting on `.offline` in a
/// presentation test is exact; asserting on `"wifi.slash"` would test spelling.
@MainActor
struct IconTests {
  @Test("every icon resolves to a symbol the system knows", arguments: Icon.allCases)
  func iconResolves(_ icon: Icon) {
    #expect(
      UIImage(systemName: icon.systemName) != nil,
      "\(icon) maps to \"\(icon.systemName)\", which SF Symbols does not know — it would render nothing"
    )
  }

  /// Two meanings sharing one glyph is not a bug, but it is always a decision.
  /// Making it visible here means it gets made on purpose.
  @Test("no two icons share a glyph by accident")
  func iconsAreDistinct() {
    let names = Icon.allCases.map(\.systemName)
    #expect(Set(names).count == names.count, "two icons resolve to the same symbol")
  }
}
