import DesignSystem
import SwiftUI

package extension View {
  /// Sends this scrollable back to its top when the reader taps the tab they
  /// are already on and there is nothing left to pop.
  ///
  /// A modifier and not a container, because the two things that scroll in this
  /// app are not the same type: `SectionScrollView` wraps a `ScrollView`, and
  /// the journey is a `List`. Both answer `.scrollPosition`, so both can answer
  /// the gesture — and neither has to reimplement it.
  func returningToTop() -> some View {
    modifier(ReturnToTopBehaviour())
  }
}

private struct ReturnToTopBehaviour: ViewModifier {
  @Environment(\.scrollToTopRequests) private var requests
  @ReducedMotion private var reducedMotion
  @State private var position = ScrollPosition()

  func body(content: Content) -> some View {
    content
      .scrollPosition($position)
      .onChange(of: requests) { _, _ in
        // `withAnimation` and not a plain assignment: the reader asked to go
        // back to the top, and a page that teleports there loses the fact that
        // it is the same page.
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
