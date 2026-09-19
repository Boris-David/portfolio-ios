import DesignSystem
import SwiftUI

/// The scrolling content of a screen — root of a tab or pushed inside one.
///
/// ## What it stopped being repeated
///
/// The **gutter**. `.padding(.horizontal, Tokens.Space.s5)` was written by hand
/// at twenty-one sites, once per block, and a block that forgot it sat flush
/// against the edge while its neighbours did not. It is a property of the page,
/// not of each thing on the page — so it is set once, here, along with the
/// reading-width bound and the bottom inset that keeps the last line clear of
/// the tab bar.
///
/// A block that must run past the gutter — a full-bleed image, a shelf that
/// scrolls sideways — cancels it locally and says so. `ProductionAppsBlock`
/// does.
///
/// ## Why it is not the only way to scroll here
///
/// The journey is a `List`, because its content is rows. It does not go through
/// this type; it applies `.returningToTop()` and carries its own insets, which
/// is what a `List` is for.
package struct SectionScrollView<Content: View>: View {
  private let content: Content

  package init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  package var body: some View {
    ScrollView {
      content
        .padding(.horizontal, Tokens.Space.s5)
        .padding(.bottom, Tokens.Space.s8)
        .readableWidth()
    }
    .returningToTop()
  }
}
