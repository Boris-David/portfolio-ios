import SwiftUI

/// What the control that dismisses a presented screen says.
///
/// A `Label` and not a `Button`: the word is view work and belongs with the
/// catalogue, while *what closing means* belongs to whoever presented the
/// screen. The composition root can then write a close button without
/// resolving a single string — which `check-layers.sh` requires of it.
public struct CloseLabel: View {
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    Text(text(InterfaceText.close))
  }
}
