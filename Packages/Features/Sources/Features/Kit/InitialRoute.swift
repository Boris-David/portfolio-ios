import Presentation
import SwiftUI

public extension EnvironmentValues {
  /// A route to push as soon as a section's stack exists.
  ///
  /// `nil` in every ordinary launch. It exists so that a **pushed** screen can
  /// be captured without anybody touching the device — the tab flags reach the
  /// four roots and the two covers, and nothing reached a destination inside a
  /// stack.
  ///
  /// It is read by `SectionShell` and not by the root, because the stack that
  /// has to receive the route is the one the shell owns.
  @Entry var initialRoute: Route?
}
