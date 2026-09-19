import Presentation
import SwiftUI

/// Presenting the open decision note — the **one** place it happens, in a given
/// presentation context.
///
/// A `Behaviour` and not a `Sheet`: `DecisionSheet` is the thing that gets
/// drawn, and this is what makes a view able to draw it. It changes what a view
/// *does*, not how it looks.
///
/// ## Why this is not part of the overlay
///
/// Because a screen can draw pins without being allowed to present. There is
/// one annotation overlay per tab shell and one per presented screen, and when
/// each of them carried its own `.sheet` bound to the shared controller, five
/// sheets were bound to one optional. SwiftUI resolved it by picking, and what
/// it picked was the settings sheet: tapping a pin anywhere did nothing until
/// the reader opened Settings, at which point the note appeared there.
///
/// ## Why a flag and not "the frontmost wins"
///
/// A sheet cannot be presented from a view that is itself covered by a sheet,
/// so the scene's anchor must stand down while a modal is up — and the modal's
/// own anchor takes over. Leaving both bound and relying on SwiftUI to ignore
/// the one that cannot present is relying on undefined behaviour to produce the
/// right answer, which is how this defect happened in the first place.
///
/// The scene knows whether a modal is open. It says so. One line, and which
/// anchor is live is then a fact rather than a race.
package struct DecisionSheetBehaviour: ViewModifier {
  private let isEnabled: Bool

  @Environment(DecisionController.self) private var decision

  package init(isEnabled: Bool) {
    self.isEnabled = isEnabled
  }

  package func body(content: Content) -> some View {
    content
      .sheet(item: Binding(
        get: { isEnabled ? decision.presented : nil },
        set: { value in
          guard value == nil, isEnabled else { return }
          decision.presented = nil
        }
      )) { note in
        DecisionSheet(note: note)
      }
  }
}

public extension View {
  /// Presents the open decision note over this view.
  ///
  /// Applied by whoever owns a presentation context: the scene, and each screen
  /// the scene presents. `isEnabled` is how the scene stands down while one of
  /// them is up.
  ///
  /// `public` and not `package`, unlike `decisionOverlay()`: the scene is the
  /// application target, which is another package. The modifier it builds stays
  /// `package` — `some View` hides it, so the type is not part of the surface.
  func decisionSheet(isEnabled: Bool = true) -> some View {
    modifier(DecisionSheetBehaviour(isEnabled: isEnabled))
  }
}
