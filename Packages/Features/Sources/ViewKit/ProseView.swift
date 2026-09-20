import CoreUI
import DesignSystem
import SwiftUI

/// Prose, set the way `design/tokens.json` says prose is set.
///
/// ## Why this exists beside `RichTextView`
///
/// `RichTextView` renders the API's **structured** rich text — spans with an
/// emphasis, already parsed by the backend. This one renders the strings the
/// app owns: interface sentences from the catalogues, where the emphasis is
/// written as Markdown because a catalogue holds text and not a tree.
///
/// Both answer to the same token, and both give up on it at the accessibility
/// text sizes for the same reason — justification needs a measure of roughly
/// forty characters, and a phone column at AX5 holds eight to twelve.
///
/// ## Why the source decides the renderer
///
/// Justification is a property of a **paragraph**. A bullet list or a code
/// block is not one, and TextKit cannot lay either out in a single label. So a
/// source carrying block-level Markdown goes to `MarkdownText`, which renders
/// the structure; everything else is split into paragraphs and each is
/// justified.
///
/// Exactly one string in this app carries a block today — the ordered list in
/// the résumé's decision note. That is not a reason to drop the distinction: it
/// is the reason the dependency that renders it is justified at all.
package struct ProseView: View {
  private let markdown: String
  private let role: ProseRole
  private let color: Color

  @Environment(\.contentLanguage) private var language
  @Environment(\.dynamicTypeSize) private var typeSize

  package init(_ markdown: String, role: ProseRole = .body, color: Color = .ink2) {
    self.markdown = markdown
    self.role = role
    self.color = color
  }

  package var body: some View {
    if canJustify {
      VStack(alignment: .leading, spacing: Tokens.Space.s3) {
        ForEach(Array(Self.paragraphs(of: markdown).enumerated()), id: \.offset) { _, paragraph in
          ProseText(markdown: paragraph, role: role, color: color, language: language.rawValue)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      MarkdownText(markdown, font: role.font, color: color)
    }
  }

  /// Justified only when the token asks for it, the column can carry it, and
  /// the source is prose rather than structure.
  private var canJustify: Bool {
    Tokens.TextAlign.prose == .justify
      && !typeSize.isAccessibilitySize
      && !Self.hasBlocks(markdown)
  }

  /// A blank line separates paragraphs — the Markdown rule, and the one the
  /// catalogues already follow.
  static func paragraphs(of markdown: String) -> [String] {
    markdown
      .components(separatedBy: "\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  /// Whether the source carries block-level Markdown: a list, a numbered list,
  /// a quote, a heading, or a fenced code block.
  ///
  /// Read line by line and at the start of a line only, because a dash or a
  /// hash inside a sentence is punctuation — "— défendue, puis obtenue" must
  /// not be mistaken for a bullet.
  static func hasBlocks(_ markdown: String) -> Bool {
    markdown.split(separator: "\n", omittingEmptySubsequences: false).contains { line in
      let trimmed = line.drop { $0 == " " }
      if trimmed.hasPrefix("```") || trimmed.hasPrefix("> ") || trimmed.hasPrefix("#") { return true }
      if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") { return true }
      let digits = trimmed.prefix { $0.isNumber }
      return !digits.isEmpty && trimmed.dropFirst(digits.count).hasPrefix(". ")
    }
  }
}
