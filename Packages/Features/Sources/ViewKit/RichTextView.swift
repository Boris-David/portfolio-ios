import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// The domain's rich text, rendered.
///
/// ## Why a single `Text`, and not an `HStack` of fragments
///
/// Concatenating `Text` with `+` produces **one** text run: it justifies, wraps
/// and aligns like a normal paragraph. An `HStack` of fragments would have
/// broken the line between emphases — a bold word jumping to the next line on
/// its own — and made selection impossible.
///
/// It is also what keeps VoiceOver correct: a paragraph is read in one breath,
/// not as eight separate announcements.
///
/// This component lives in `ViewKit` and not in `DesignSystem`: it knows
/// `RichText`, which is a **domain** type. A design system that knows its app's
/// domain stops being reusable anywhere else.
package struct RichTextView: View {
  private let value: RichText
  private let font: Font
  private let color: Color

  public init(_ value: RichText, font: Font = Typography.body, color: Color = .ink2) {
    self.value = value
    self.font = font
    self.color = color
  }

  public var body: some View {
    value.spans.reduce(Text("")) { accumulated, span in
      accumulated + styled(span)
    }
    .font(font)
    .foregroundStyle(color)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func styled(_ span: RichText.Span) -> Text {
    switch span.emphasis {
    case .plain:
      Text(span.text)
    case .strong:
      // Weight **and** primary ink: weight alone is not enough to lift a
      // fragment out of a paragraph set in secondary ink.
      Text(span.text).fontWeight(.semibold).foregroundColor(.ink)
    case .code:
      Text(span.text).font(Typography.code).foregroundColor(.accent)
    }
  }
}
