import CoreUI
import DesignSystem
import Domain
import SwiftUI
import ViewKit

/// A component's explanation, revealed in stages.
///
/// ## The tension this resolves, and it is a real one
///
/// The owner asked for **more** explanation inside an app he had already judged
/// too textual. Both are true at once, and the answer is not to pick one: it is
/// progressive disclosure.
///
/// 1. at rest, **nothing** — the app is an app;
/// 2. annotations on: numbered pins;
/// 3. a tap: the component's name and one sentence, at a small detent;
/// 4. "learn more": the whole thing, with what was ruled out.
///
/// The long text does not disappear. It stops being the first thing anyone
/// sees, which was the actual complaint.
///
/// ## Why the detent is the disclosure
///
/// A "read more" that expands a section inside a fixed sheet would push the
/// content the reader is holding their thumb over. The detent moves the
/// **sheet**, so the first sentence stays exactly where it was and more appears
/// below it. It is also draggable, so the same gesture works without finding a
/// button.
///
/// ## Why this order below
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

  /// The height at which only the component's name and its one sentence show.
  ///
  /// A fraction and not `.medium`: half a phone is far more than one sentence
  /// needs, and the point of the first stage is that it does not cover what it
  /// describes.
  @State private var detent: PresentationDetent = .fraction(0.32)

  public init(note: BackstageNote) {
    self.note = note
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s5) {
          header

          if detent != .large {
            learnMore
          }

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
    .presentationDetents([.fraction(0.32), .large], selection: $detent)
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

  /// The step from "what is it" to "why, and what was ruled out".
  ///
  /// Present even though the sheet can be dragged: a gesture nobody is told
  /// about is a gesture most readers never make. The button is the discoverable
  /// path, the drag is the fast one.
  private var learnMore: some View {
    Button {
      withAnimation(Motion.disclosure) { detent = .large }
    } label: {
      HStack(spacing: Tokens.Space.s2) {
        Text(BackstageLabels.learnMore(language))
        Image(systemName: "chevron.down")
          .font(.system(size: Tokens.Icon.caption, weight: .semibold))
      }
      .font(Typography.secondary)
      .foregroundStyle(Color.accent)
    }
    .accessibilityHint(BackstageLabels.learnMoreHint(language))
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
