import DesignSystem
import SwiftUI

/// A tab root's scrolling content — and the half of "tap the tab again" that a
/// navigation stack cannot do.
///
/// ## Why a component and not a modifier on each `ScrollView`
///
/// Because it owns state. Returning to the top needs a `ScrollPosition`, and a
/// position has to live somewhere that survives a redraw. Four screens each
/// declaring `@State private var position` and each remembering to wire the
/// same `onChange` is four chances to forget one — and a gesture that works on
/// three tabs out of four reads as a bug, not as a missing feature.
///
/// It also carries the two things every tab root was repeating by hand: the
/// reading-width bound and the bottom inset that keeps the last line clear of
/// the tab bar.
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
