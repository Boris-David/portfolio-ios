import DesignSystem
import SwiftUI

/// The label on the control that shows or hides the decision annotations.
///
/// It lives here rather than with the accessory that presents it, for the same
/// reason as `SectionLabel`: reading a catalogue is view work. The composition
/// root owns *where* the control sits and *what it toggles*; what it says is
/// decided one layer down.
public struct DecisionsToggleLabel: View {
  private let isOn: Bool

  @Localized(.interface) private var text

  public init(isOn: Bool) {
    self.isOn = isOn
  }

  public var body: some View {
    Label(
      text(isOn ? InterfaceText.decisionsHide : InterfaceText.decisionsShow),
      systemImage: isOn ? "number.circle.fill" : "number.circle"
    )
    .font(Typography.secondary)
    .frame(maxWidth: .infinity)
  }
}
