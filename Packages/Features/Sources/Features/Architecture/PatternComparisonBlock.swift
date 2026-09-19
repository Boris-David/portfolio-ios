import CoreUI
import Decisions
import DesignSystem
import Domain
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// Four architecture patterns, compared — one at a time, in the same four slots.
///
/// ## Why it stopped being a table
///
/// It was a `Grid` that scrolled sideways, and the doc above it defended that
/// choice honestly: the alignment **is** the argument, four columns of prose
/// need about a thousand points, and wrapping them would undo the comparison.
///
/// All true, and it did not survive a phone. The arithmetic was written down in
/// that same comment: a margin, the label column, a gap and one pattern column
/// come to 408 points on a 402-point screen, so the first column was **cut by
/// construction** — and the fix at the time was to leave the scroll indicator
/// visible so the cut read as an affordance rather than a bug. That is a note
/// admitting the layout does not fit.
///
/// ## What replaces it, and why it still compares
///
/// A comparison works when the slots stay still and the content changes. Here
/// the four questions — what it buys, what it costs, when to choose it, when it
/// breaks — hold their position, and the pattern is what moves. Switching is one
/// tap instead of a thousand points of sideways scrolling, the answers land in
/// the same place every time, and the difference is therefore the only thing
/// that moves on screen.
///
/// ## Why capsules and not a segmented `Picker`
///
/// The names come from the API, and one of them is *Clean Architecture*. Four
/// segments on a 402-point screen give each about 95 points; the longest name
/// would have been truncated to a word and a half. A row that scrolls holds any
/// name the content gives it.
struct PatternComparisonBlock: View {
  let patterns: [ArchitecturePattern]

  @State private var selected: ArchitecturePattern.ID?
  @Localized(.interface) private var text

  private var current: ArchitecturePattern? {
    patterns.first { $0.id == selected } ?? patterns.first
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.comparison)).eyebrowStyle()

      selector

      if let current {
        card(current)
          // The card is one object that changes content, not four cards that
          // replace each other: the identity stays, so the criteria keep their
          // place and only the prose crossfades.
          .transition(.opacity)
          .animation(Motion.interactive, value: current.id)
      }
    }
    .decision(ArchitectureDecisions.comparison)
  }

  private var selector: some View {
    ScrollView(.horizontal) {
      HStack(spacing: Tokens.Space.s2) {
        ForEach(patterns) { pattern in
          Button {
            selected = pattern.id
          } label: {
            Text(pattern.name)
              .font(Typography.secondary)
              .fontWeight(current?.id == pattern.id ? .semibold : .regular)
              .foregroundStyle(current?.id == pattern.id ? Color.onAccent : Color.ink2)
              .padding(.horizontal, Tokens.Space.s4)
              .padding(.vertical, Tokens.Space.s2)
              .frame(minHeight: Tokens.Accessibility.minimumTouchTarget)
              .background(
                Capsule().fill(current?.id == pattern.id ? Color.accent : Color.paper2)
              )
              .overlay(
                Capsule().strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
              )
              .contentShape(Capsule())
          }
          .buttonStyle(.pressableCard)
          .accessibilityAddTraits(current?.id == pattern.id ? [.isButton, .isSelected] : .isButton)
        }
      }
      // The row bleeds to the screen edge and gives the inset back inside, so a
      // capsule that is cut is visibly cut rather than looking like the end.
      .padding(.horizontal, Tokens.Space.s5)
    }
    .padding(.horizontal, -Tokens.Space.s5)
    .scrollIndicators(.hidden)
    // Tied to the value that changed, not to the tap: it cannot fire for a tap
    // on the capsule that is already selected.
    .feedback(.selectionChanged, on: current?.id)
  }

  private func card(_ pattern: ArchitecturePattern) -> some View {
    Surface {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
          Text(text(InterfaceText.separatesLabel)).eyebrowStyle()
          Text(pattern.separates)
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)

        ForEach(ArchitecturePattern.Criterion.allCases, id: \.self) { criterion in
          Divider().overlay(Color.line)
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            Text(text(criterion.labelKey)).eyebrowStyle()
            RichTextView(pattern.answer(to: criterion), font: Typography.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}
