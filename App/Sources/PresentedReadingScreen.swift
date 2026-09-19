import Decisions
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// A reading that would have been a third push, presented instead.
///
/// ## Why it has its own stack
///
/// Because it has a title, and a title needs a bar to sit in. It is a stack of
/// exactly one: a reading presented this way is the end of the road, and
/// offering to go deeper from here would rebuild the corridor it exists to
/// avoid.
///
/// ## Why it lives in the composition root
///
/// It names `RouteScreen`, which is the one type that sees every feature. A
/// screen module could not build this without being allowed to see its
/// siblings — which is the boundary the whole resolver exists to keep.
struct PresentedReadingScreen: View {
  let route: Route

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      RouteScreen(route: route)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button { dismiss() } label: { CloseLabel(.mark) }
          }
        }
    }
    // Full height, and leaveable two ways: the cross, and the downward swipe
    // every sheet answers by default. Nothing here disables the gesture —
    // `interactiveDismissDisabled` is for unsaved work, and a reading has none.
    .presentationDetents([.large])
    .decisionSheet()
  }
}
