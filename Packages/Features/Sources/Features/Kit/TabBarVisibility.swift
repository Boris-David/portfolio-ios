import SwiftUI

package extension View {
  /// Says whether this screen wants the tab bar under it.
  ///
  /// ## Why every screen says it, including the ones that want it
  ///
  /// It was declared in one place — hidden on the pushed destination — and the
  /// roots said nothing, relying on the system to put the bar back on the way
  /// out. It does not, reliably: after a few pushes and pops the reader ended
  /// up on a **tab root with no tab bar at all**, and no gesture brought it
  /// back.
  ///
  /// A visibility that is only ever set in one direction is a state machine
  /// with one transition, and SwiftUI restores the other one on its own
  /// schedule. Saying it at both ends removes the restore from the story: every
  /// screen declares what it wants, so what the reader gets is never the
  /// leftover of where they have been.
  ///
  /// Named rather than written out, for the reason the whole codebase names its
  /// modifiers: `.tabBar(.hidden)` says the intent, `.toolbar(.hidden, for:
  /// .tabBar)` says the mechanism.
  func tabBar(_ visibility: Visibility) -> some View {
    toolbar(visibility, for: .tabBar)
  }
}
