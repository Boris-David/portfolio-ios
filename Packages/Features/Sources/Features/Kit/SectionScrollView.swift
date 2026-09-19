import DesignSystem
import SwiftUI

/// The scrolling content of a screen — root of a tab or pushed inside one.
///
/// ## Why a component and not a modifier on each `ScrollView`
///
/// Because it owns state. Returning to the top needs a `ScrollPosition`, and a
/// position has to live somewhere that survives a redraw. Four screens each
/// declaring `@State private var position` and each remembering to wire the
/// same `onChange` is four chances to forget one — and a gesture that works on
/// three tabs out of four reads as a bug, not as a missing feature.
///
/// ## What it also stopped being repeated
///
/// The **gutter**. `.padding(.horizontal, Tokens.Space.s5)` was written by hand
/// at twenty-one sites, once per block, and a block that forgot it sat flush
/// against the edge while its neighbours did not. It is a property of the page,
/// not of each thing on the page — so it is set once, here, along with the
/// reading-width bound and the bottom inset that keeps the last line clear of
/// the tab bar.
///
/// A block that must run past the gutter — a full-bleed image — cancels it
/// locally and says so. Nothing does today.
package struct SectionScrollView<Content: View>: View {
  private let content: Content

  @Environment(\.scrollToTopRequests) private var scrollToTopRequests
  @ReducedMotion private var reducedMotion
  @State private var position = ScrollPosition()

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
    .scrollPosition($position)
    .onChange(of: scrollToTopRequests) { _, _ in
      // `withAnimation` and not a plain assignment: the reader asked to go back
      // to the top, and a page that teleports there loses the fact that it is
      // the same page.
      withAnimation(reducedMotion ? nil : Motion.disclosure) {
        position.scrollTo(edge: .top)
      }
    }
  }
}

package extension EnvironmentValues {
  /// How many times the section containing this view has been asked for its
  /// top — see `SectionShell.returnToStart()`.
  ///
  /// A count rather than a flag, for the same reason `SectionReselection` keeps
  /// one: the gesture repeats, and two identical values in a row are one change.
  @Entry var scrollToTopRequests = 0
}
