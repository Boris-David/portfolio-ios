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
/// ## Why there is no chevron
///
/// There was one, pointing up, on the reasoning that a cover rises from the
/// bottom edge. A chevron is a promise of *more* — another level, a list that
/// unfolds — and this opens one document. The author's verdict was short: it
/// serves no purpose. The whole capsule is the target; nothing needs to point
/// at anything.
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
    }
    .padding(.horizontal, Tokens.Space.s4)
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(text(InterfaceText.resumeAction))
  }
}
