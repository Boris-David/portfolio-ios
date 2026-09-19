import CoreUI
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The control docked under the tab bar on iOS 26.
///
/// ## Why the résumé and not the annotations toggle
///
/// It held the toggle, on the reasoning that `tabViewBottomAccessory` is for a
/// **persistent** control and an annotations mode is persistent. True, and
/// beside the point: the slot is the most visible surface iOS 26 offers, it
/// follows the reader through every tab, and it was spending that on a debug
/// switch — in an app whose one job is to get a CV read.
///
/// The toggle lost nothing. It is a row in Settings, reachable from the toolbar
/// of every tab root, and it is presented and explained on the engineering
/// screen. It was never only here.
extension View {
  @ViewBuilder
  func resumeAccessory(present: PresentAction, isOpen: Bool) -> some View {
    if #available(iOS 26.0, *) {
      tabViewBottomAccessory {
        Button { present(.resume) } label: {
          ResumeAccessoryLabel()
        }
        // ⚠️ `.plain` gave the most-used control in the app **no press state
        // at all**: the finger went down, nothing moved, and the only sign
        // anything had happened was the cover arriving a moment later. The same
        // style every card in the app uses, and the haptic that says the tap
        // registered before the screen does.
        .buttonStyle(.pressableCard)
        .feedback(.selectionChanged, on: isOpen)
      }
    } else {
      // iOS 18 has no bar accessory, so the résumé keeps the toolbar item it
      // has always had — see `SectionShell.toolbar`. A hand-built floating
      // control would have covered content and duplicated a command that
      // already exists.
      self
    }
  }
}
