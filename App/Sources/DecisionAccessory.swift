import Decisions
import DesignSystem
import Presentation
import SwiftUI
import ViewKit

/// The control docked under the tab bar on iOS 26.
///
/// It carries the decision toggle, because that is what the system provides
/// this slot for: a **persistent** control that follows the user through the
/// whole navigation — which is exactly what an annotations mode is.
extension View {
  @ViewBuilder
  func engineeringAccessory(isOn: Binding<Bool>) -> some View {
    if #available(iOS 26.0, *) {
      tabViewBottomAccessory {
        Button {
          isOn.wrappedValue.toggle()
        } label: {
          DecisionsToggleLabel(isOn: isOn.wrappedValue)
        }
        .tint(Color.accent)
      }
    } else {
      // iOS 18 has no bar accessory: the toggle lives in the Decisions tab,
      // where it is presented and explained anyway. A hand-built floating
      // control would have covered content and duplicated a command that
      // already exists.
      self
    }
  }
}
