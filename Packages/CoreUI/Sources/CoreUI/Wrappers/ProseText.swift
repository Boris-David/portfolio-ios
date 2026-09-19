import DesignSystem
import SwiftUI
import UIKit

/// A paragraph of prose, laid out by TextKit so it can be **justified**.
///
/// ## Why this exists at all
///
/// `design/tokens.json` says how a paragraph is set, and it says `justify` —
/// shared with the website and the résumé so the three cannot drift apart.
/// SwiftUI cannot honour it: `TextAlignment` has three cases, and none of them
/// is justified. So one surface out of three needs a different mechanism, which
/// is precisely what the token's vocabulary was made neutral for.
///
/// ## What it costs, stated rather than hidden
///
/// A `UILabel` is not a `Text`. It gives up **text selection**, which the
/// concatenated `Text` had. It is kept where a paragraph is read and not
/// quoted; headings, captions and anything a reader might copy stay in SwiftUI.
///
/// Dynamic Type is **not** given up: the caller resolves its fonts against the
/// current content size category, and SwiftUI re-runs this view when that
/// changes — which is what makes `updateUIView` rebuild the string.
///
/// ## Why hyphenation comes with it
///
/// Justified text without hyphenation is the thing justification is accused of:
/// to flush both margins the engine widens the spaces, and a long French word
/// at the end of a short line opens a river of white. The website needed
/// `hyphens: auto` for the same reason, and had to bound it — left alone it cut
/// a six-letter company name in half.
public struct ProseText: UIViewRepresentable {
  private let attributed: AttributedString
  private let alignment: Tokens.TextAlign.Alignment

  public init(_ attributed: AttributedString, alignment: Tokens.TextAlign.Alignment = Tokens.TextAlign.prose) {
    self.attributed = attributed
    self.alignment = alignment
  }

  public func makeUIView(context: Context) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    // Without these, SwiftUI's proposal wins over the text's own height and the
    // last lines are clipped — the same class of defect as a missing
    // `fixedSize` on a `Text`, which this codebase has paid for three times.
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }

  public func updateUIView(_ label: UILabel, context: Context) {
    let text = NSMutableAttributedString(attributed)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment.textKit
    paragraph.lineBreakMode = .byWordWrapping
    // TextKit's hyphenation is a 0–1 factor and not a length, so it cannot
    // express "at least eight letters" the way CSS can. `1` lets it hyphenate
    // wherever the locale's dictionary allows, which on a phone column is what
    // keeps the spacing even.
    paragraph.hyphenationFactor = 1
    text.addAttribute(
      .paragraphStyle,
      value: paragraph,
      range: NSRange(location: 0, length: text.length)
    )
    label.attributedText = text
  }

  /// Reports the height the text actually needs at the proposed width.
  ///
  /// A representable that does not answer this gets whatever SwiftUI guessed,
  /// and a paragraph is then cut off at the bottom with nothing to say so.
  public func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView label: UILabel,
    context: Context
  ) -> CGSize? {
    guard let width = proposal.width, width > 0, width < .infinity else { return nil }
    let fitted = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    return CGSize(width: width, height: ceil(fitted.height))
  }
}

public extension Tokens.TextAlign.Alignment {
  /// The SwiftUI case, where one exists.
  ///
  /// `justify` has none — that is the whole reason `ProseText` exists — and it
  /// answers `nil` rather than quietly becoming `.leading`, so a caller has to
  /// decide what to do about it.
  var swiftUI: TextAlignment? {
    switch self {
    case .start: .leading
    case .center: .center
    case .end: .trailing
    case .justify: nil
    }
  }

  /// The TextKit case. All four exist here, which is why the justified path
  /// goes through UIKit.
  var textKit: NSTextAlignment {
    switch self {
    case .start: .natural
    case .center: .center
    case .end: .right
    case .justify: .justified
    }
  }
}

public extension UIFont {
  /// The same face, semibold.
  ///
  /// Built from the descriptor rather than from a point size, so a font that
  /// arrived scaled by Dynamic Type stays scaled.
  var semibold: UIFont {
    let descriptor = fontDescriptor.addingAttributes([
      .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold],
    ])
    return UIFont(descriptor: descriptor, size: 0)
  }
}
