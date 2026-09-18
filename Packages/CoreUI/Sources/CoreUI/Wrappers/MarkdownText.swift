import DesignSystem
import SwiftUI
import Textual

/// Markdown, rendered.
///
/// ## The name deliberately does not say "Textual"
///
/// This file is the **only** one in the repository that names the library — a
/// requirement, not a preference: *"I must not have `import Textual` in my code
/// files, but `import CoreUI`, so that the day I change library I do not have to
/// change an import."*
///
/// Everything above asks for `MarkdownText(source)`. Replacing the renderer
/// costs this file, and the call sites do not move. With `import Textual`
/// scattered through thirty views it would cost thirty files and a diff nobody
/// can review.
///
/// ## Why a library at all rather than `Text(.init(markdown:))`
///
/// `AttributedString`'s initialiser handles **inline** markup only — bold, code,
/// links. It knows nothing of lists or code blocks, which are precisely what a
/// technical explanation needs.
///
/// ## Why Textual and not MarkdownUI, by the same author
///
/// MarkdownUI has moved to maintenance mode and points explicitly at Textual,
/// which builds on `AttributedString` — therefore on the system's own text
/// rendering, with the Dynamic Type and text selection that come with it,
/// instead of a rebuilt view tree.
/// ## Configurable, because a component library that is not gets copied
///
/// Font and colour are parameters with sensible defaults rather than something
/// the caller wraps afterwards. A component people have to decorate at every
/// call site is a component somebody eventually reimplements next door — which
/// is the duplication this package exists to end.
public struct MarkdownText: View {
  private let source: String
  private let font: Font
  private let color: Color

  public init(_ source: String, font: Font = Typography.body, color: Color = .ink2) {
    self.source = source
    self.font = font
    self.color = color
  }

  public var body: some View {
    StructuredText(markdown: source)
      .font(font)
      .foregroundStyle(color)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// A single line of **inline** Markdown — bold, italic, code, links.
///
/// ## Why not just `Text(string)`
///
/// `Text` treats a `String` as literal text: `*is*` shows with its asterisks,
/// and `` `import` `` with its backticks. The defect was visible on screen, in
/// the Decisions tab — an app that explains the care it takes over details while
/// displaying raw markup contradicts itself.
///
/// `Text(LocalizedStringKey)` **interprets** inline Markdown, which is exactly
/// what is needed here, and costs no library. Lists and code blocks go to
/// `MarkdownText`.
public struct InlineMarkdown: View {
  private let source: String
  private let font: Font
  private let color: Color

  public init(_ source: String, font: Font = Typography.body, color: Color = .ink2) {
    self.source = source
    self.font = font
    self.color = color
  }

  public var body: some View {
    Text(LocalizedStringKey(source))
      .font(font)
      .foregroundStyle(color)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
