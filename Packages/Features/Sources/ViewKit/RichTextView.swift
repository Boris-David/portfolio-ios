import CoreUI
import DesignSystem
import Domain
import SwiftUI
import UIKit

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

  /// The reader's text size, read so the UIKit path can resolve its fonts
  /// against it — SwiftUI re-runs this view when it changes, which is what
  /// keeps the justified paragraph answering Dynamic Type.
  @Environment(\.dynamicTypeSize) private var typeSize

  /// The language the content is in — not the device's. It is what decides
  /// which hyphenation dictionary breaks the words.
  @Environment(\.contentLanguage) private var language

  public var body: some View {
    // Two renderers for one paragraph, and the token decides which.
    //
    // SwiftUI's `Text` is the better one — selection, and a single text run
    // that wraps and aligns like a paragraph should. It simply has no
    // justified case. So `justify` is the only value that costs a trip through
    // TextKit, and every other value stays where it was.
    if let alignment = usableAlignment.swiftUI {
      concatenated
        .multilineTextAlignment(alignment)
        .fixedSize(horizontal: false, vertical: true)
    } else {
      ProseText(attributed, language: language.rawValue)
    }
  }

  /// The token's alignment, unless the column can no longer carry it.
  ///
  /// ## Why the platform gets to say no
  ///
  /// Justification needs a **measure** — roughly forty characters a line — to
  /// distribute the slack across enough word gaps that none of them shows. At
  /// the accessibility text sizes a phone column holds eight to twelve
  /// characters, so the slack lands between two words, or one, and the
  /// paragraph comes apart: measured at AX5, "Actuellement" and "ingénieur"
  /// each took a line of their own with the space stretched until the words
  /// read as separated letters.
  ///
  /// This is not the token being overruled. The token says how prose is set;
  /// this says when this surface can honour it — the same judgment the website
  /// makes when it justifies editorial paragraphs and leaves a three-word
  /// caption alone.
  private var usableAlignment: Tokens.TextAlign.Alignment {
    typeSize.isAccessibilitySize ? .start : Tokens.TextAlign.prose
  }

  private var concatenated: Text {
    value.spans
      .reduce(Text("")) { accumulated, span in accumulated + styled(span) }
      .font(font)
      .foregroundStyle(color)
  }

  /// The same spans, as an attributed string TextKit can lay out.
  ///
  /// The fonts are resolved to `UIFont` here rather than carried as SwiftUI
  /// `Font`s: a `UILabel` cannot render the latter, and a paragraph that
  /// renders with the system default is a paragraph whose typography quietly
  /// left the design system.
  private var attributed: AttributedString {
    var result = AttributedString()
    for span in value.spans {
      var run = AttributedString(span.text)
      switch span.emphasis {
      case .plain:
        run.uiKit.font = .preferredFont(forTextStyle: .body)
        run.uiKit.foregroundColor = UIColor(color)
      case .strong:
        // Weight **and** primary ink: weight alone is not enough to lift a
        // fragment out of a paragraph set in secondary ink.
        run.uiKit.font = .preferredFont(forTextStyle: .body).semibold
        run.uiKit.foregroundColor = UIColor(Color.ink)
      case .code:
        run.uiKit.font = .monospacedSystemFont(
          ofSize: UIFont.preferredFont(forTextStyle: .callout).pointSize,
          weight: .regular
        )
        run.uiKit.foregroundColor = UIColor(Color.accent)
      }
      result.append(run)
    }
    return result
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
