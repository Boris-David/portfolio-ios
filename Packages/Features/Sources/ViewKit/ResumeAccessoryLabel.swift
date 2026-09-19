import DesignSystem
import Presentation
import SwiftUI

/// What the control docked under the tab bar says.
///
/// It lives here rather than with the accessory that presents it, for the same
/// reason as `SectionLabel`: reading a catalogue is view work. The composition
/// root owns *where* the control sits and *what it opens*; what it says is
/// decided one layer down.
///
/// The arrow points **up** because that is where the document comes from — a
/// cover rises from the bottom edge. A chevron that pointed right would promise
/// a push, and the reader would expect a back button that does not exist.
public struct ResumeAccessoryLabel: View {
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    HStack(spacing: Tokens.Space.s3) {
      Image(Icon.resume)
        .font(.system(size: Tokens.Icon.action, weight: .semibold))
        .foregroundStyle(Color.accent)

      Text(text(InterfaceText.resumeAction))
        .font(Typography.bodyStrong)
        .foregroundStyle(Color.ink)
        .lineLimit(1)

      Spacer(minLength: Tokens.Space.s2)

      Image(systemName: "chevron.up")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.ink3)
    }
    .padding(.horizontal, Tokens.Space.s4)
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(text(InterfaceText.resumeAction))
  }
}
