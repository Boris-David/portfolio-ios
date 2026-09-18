import CoreUI
import DesignSystem
import Domain
import SwiftUI
import ViewKit

/// A component's explanation, in detail.
///
/// It answers, in order, the questions a technical reviewer would ask: *what is
/// it*, *why this one*, *what was ruled out*, *when to use it*, *what breaks*.
///
/// The order is not neutral. "What was ruled out" comes **before** "when to use
/// it" because it is the part that gets dropped when room runs short, and it is
/// precisely the part that separates a decision from a reflex.
package struct BackstageSheet: View {
  private let note: BackstageNote
  @Environment(\.dismiss) private var dismiss
  @Environment(\.contentLanguage) private var language

  public init(note: BackstageNote) {
    self.note = note
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s5) {
          header

          section(BackstageLabels.why(language)) {
            markdown(note.rationale(language))
          }

          if !note.rejected.isEmpty {
            section(BackstageLabels.rejected(language)) {
              VStack(alignment: .leading, spacing: Tokens.Space.s3) {
                ForEach(note.rejected, id: \.name) { rejected in
                  rejectedRow(rejected)
                }
              }
            }
          }

          section(BackstageLabels.whenToUse(language)) {
            markdown(note.whenToUse(language))
          }

          if let pitfall = note.pitfall {
            section(BackstageLabels.pitfall(language)) {
              HStack(alignment: .top, spacing: Tokens.Space.s3) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(Color.accent)
                  .font(.footnote)
                  .padding(.top, 3)
                markdown(pitfall(language))
              }
              .padding(Tokens.Space.s4)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                  .fill(Color.accentWash)
              )
            }
          }

          if let documentation = note.documentation {
            Link(destination: documentation) {
              Label(BackstageLabels.documentation(language), systemImage: "arrow.up.right")
            }
            .buttonStyle(.adaptiveGlass)
            .padding(.top, Tokens.Space.s2)
          }
        }
        .padding(Tokens.Space.s5)
      }
      .background(Color.paper)
      .navigationTitle(note.component)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(BackstageLabels.close(language)) { dismiss() }
        }
      }
    }
    // An explanation is skimmed first: a half-height sheet keeps the component
    // it describes in view, and expands for anyone who wants all of it.
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  // ───────────────────────────────────────────────────────────────────────

  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(note.component)
        .font(Typography.code)
        .foregroundStyle(Color.accent)
      Text(note.role(language))
        .font(Typography.heading)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(title).eyebrowStyle()
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func rejectedRow(_ rejected: BackstageNote.Rejected) -> some View {
    HStack(alignment: .top, spacing: Tokens.Space.s3) {
      // A bar rather than a cross: "ruled out" is not "bad". Most of these
      // candidates are good tools, in the wrong place.
      RoundedRectangle(cornerRadius: 1)
        .fill(Color.line2)
        .frame(width: 3)
      VStack(alignment: .leading, spacing: 2) {
        Text(rejected.name(language))
          .font(Typography.bodyStrong)
          .foregroundStyle(Color.ink)
        Text(rejected.because(language))
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  /// Markdown rendered by **Textual**, into a native `AttributedString`.
  ///
  /// Why a library rather than `Text(.init(markdown))`: `AttributedString`'s
  /// initialiser handles **inline** only — bold, code, links. It knows nothing
  /// of lists or code blocks, which are exactly what a technical explanation
  /// needs.
  ///
  /// Why Textual and not MarkdownUI, by the same author: MarkdownUI has moved to
  /// maintenance mode and points explicitly at Textual, which builds on
  /// `AttributedString` — therefore on the system's text rendering, with the
  /// Dynamic Type and selection that come with it, instead of a rebuilt view
  /// tree.
  private func markdown(_ source: String) -> some View {
    MarkdownText(source)
      .font(Typography.body)
      .foregroundStyle(Color.ink2)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
