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
/// ## Why hyphenation comes with it — and why it is bounded here
///
/// Justified text without hyphenation is the thing justification is accused of:
/// to flush both margins the engine widens the spaces, and a long French word
/// at the end of a short line opens a river of white. The website needed
/// `hyphens: auto` for the same reason, and had to bound it — left alone it cut
/// a seven-letter company name in half.
///
/// TextKit's own `hyphenationFactor` is a 0–1 eagerness and **not** a length,
/// so it cannot express that bound. Left at `1` it produced exactly the defect
/// the website had fixed: "In-stant System", in a capture of the open projects
/// card. The factor is therefore `0`, and the break opportunities are computed
/// here instead — with the same limits as the stylesheet — and written into the
/// string as soft hyphens, which the line breaker honours on their own.
public struct ProseText: UIViewRepresentable {
  private let attributed: AttributedString
  private let alignment: Tokens.TextAlign.Alignment
  private let language: String

  /// - Parameter language: the language the **content** is in, as a BCP-47
  ///   code. It is an argument and never `Locale.current`: the reader chooses
  ///   the content's language in the app, the device has its own, and hyphenating
  ///   French text with an English dictionary is the same class of defect as
  ///   reading a French catalogue because the phone is French.
  public init(
    _ attributed: AttributedString,
    alignment: Tokens.TextAlign.Alignment = Tokens.TextAlign.prose,
    language: String
  ) {
    self.attributed = attributed
    self.alignment = alignment
    self.language = language
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
    Hyphenation.mark(text, language: language)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment.textKit
    paragraph.lineBreakMode = .byWordWrapping
    // Zero, because the breaks are chosen above and marked with soft hyphens.
    // Any positive value here would add the engine's own unbounded ones back.
    paragraph.hyphenationFactor = 0
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

/// Where a word may be broken, decided here rather than by TextKit.
///
/// ## The rule, and where it comes from
///
/// The stylesheet says `hyphenate-limit-chars: 8 4 4`: a word of at least eight
/// letters, with at least four before the hyphen and four after. That rule is
/// what stops "Instant" and "Inetum" from being cut, and TextKit has no way to
/// state it. So the same three numbers live here, and the break opportunities
/// are marked with U+00AD, which the line breaker honours whatever the
/// hyphenation factor is.
///
/// ⚠️ These three numbers exist twice — here and in `web/src/styles/base.css`.
/// That is a duplication, and it is named rather than hidden: the honest home
/// for them is `design/tokens.json`, beside the alignment they serve.
enum Hyphenation {
  /// The shortest word worth breaking.
  static let minimumWordLength = 8
  /// The fewest letters that may stay on the line being ended.
  static let minimumBefore = 4
  /// The fewest that must move to the next one.
  static let minimumAfter = 4

  /// Inserts a soft hyphen at every break the rule allows.
  ///
  /// Insertions are applied from the end backwards so that earlier offsets stay
  /// valid — the classic mistake this loop is written to avoid.
  static func mark(_ text: NSMutableAttributedString, language: String) {
    let locale = Locale(identifier: language) as CFLocale
    guard CFStringIsHyphenationAvailableForLocale(locale) else { return }

    let string = text.string as NSString
    var breaks: [Int] = []

    string.enumerateSubstrings(
      in: NSRange(location: 0, length: string.length),
      options: [.byWords, .localized]
    ) { word, range, _, _ in
      guard let word, word.count >= minimumWordLength else { return }

      let first = range.location + minimumBefore
      let last = range.location + range.length - minimumAfter
      var searchBefore = last

      while searchBefore > first {
        let found = CFStringGetHyphenationLocationBeforeIndex(
          string as CFString,
          searchBefore,
          CFRange(location: range.location, length: range.length),
          0,
          locale,
          nil
        )
        guard found != kCFNotFound, found >= first, found <= last else { break }
        breaks.append(found)
        searchBefore = found
      }
    }

    for offset in breaks.sorted(by: >) {
      text.insert(NSAttributedString(string: "\u{00AD}"), at: offset)
    }
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
