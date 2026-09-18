import Decisions
import DesignSystem
import Domain
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// The comparison itself: one column per pattern, one row per question.
///
/// ## Why a `Grid`
///
/// Because the alignment **is** the argument. A table only compares if "what it
/// costs" starts on the same line for all four patterns; the moment a row
/// measures itself alone, the columns drift and the reader stops being able to
/// scan across. `Grid` measures every cell before placing any of them, so a
/// column is as wide as its widest cell in any row, and a row is as tall as its
/// tallest cell — which is the definition of a table and the one thing stacks
/// cannot do.
///
/// ## Why it scrolls sideways
///
/// Four columns of prose need about a thousand points. Wrapping them would undo
/// the comparison; shrinking them would make them unreadable. So the table keeps
/// its real width and the reader moves along it — one gesture, and every row
/// still lines up because the grid, not the viewport, decides the geometry.
struct PatternComparisonBlock: View {
  let patterns: [ArchitecturePattern]

  @Localized(.interface) private var text

  // The two column widths **scale with the text**. A column fixed at 248 points
  // holds seven words at the default size and two at the accessibility sizes,
  // where every cell turns into a column of single words. `@ScaledMetric` keeps
  // the measure — roughly seven words a line — rather than the number, and the
  // token stays the one place the number is written.
  @ScaledMetric(relativeTo: .subheadline)
  private var columnWidth = Tokens.Layout.comparisonColumnWidth
  @ScaledMetric(relativeTo: .caption)
  private var labelWidth = Tokens.Layout.comparisonLabelWidth

  /// The label column, plus one column per pattern — what a full-width rule has
  /// to span.
  private var columnCount: Int { patterns.count + 1 }

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.comparison))
        .eyebrowStyle()
        .padding(.horizontal, Tokens.Space.s5)

      ScrollView(.horizontal) {
        Grid(
          alignment: .topLeading,
          horizontalSpacing: Tokens.Space.s5,
          verticalSpacing: Tokens.Space.s4
        ) {
          headerRow
          ForEach(ArchitecturePattern.Criterion.allCases, id: \.self) { criterion in
            rule
            criterionRow(criterion)
          }
        }
        .decision(ArchitectureDecisions.grid)
      }
      // The table bleeds to the screen edge and insets its content instead of
      // being padded: padding would have clipped the scroll, and the last column
      // would have ended flush against the bezel with nothing to show it was the
      // last one.
      .contentMargins(.horizontal, Tokens.Space.s5, for: .scrollContent)
      // ⚠️ The indicator stays **visible**, and that is the fix to a real
      // defect rather than a preference.
      //
      // The arithmetic does not fit and is not meant to: a margin, the label
      // column, a gap and one pattern column come to 408 points on a 402-point
      // phone. The first column is therefore cut, on purpose — that is what
      // "the table keeps its real width and the reader moves along it" means.
      //
      // Hidden, the cut read as a rendering bug: a sentence stopping mid-word at
      // the bezel, with nothing to say a gesture would finish it. The scroll bar
      // costs two pixels and turns a defect into an affordance.
    }
  }

  // ── The rows ───────────────────────────────────────────────────────────

  /// The heading of each column: the pattern, and what it pulls apart.
  private var headerRow: some View {
    GridRow {
      Text(text(InterfaceText.separatesLabel))
        .eyebrowStyle()
        .frame(width: labelWidth, alignment: .leading)

      ForEach(patterns) { pattern in
        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
          Text(pattern.name)
            .font(Typography.heading)
            .foregroundStyle(Color.accent)
          Text(pattern.separates)
            .font(Typography.secondary)
            .foregroundStyle(Color.ink2)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: columnWidth, alignment: .leading)
        // A column is one thing to VoiceOver: the name and what it separates are
        // read together, or the name is announced with nothing attached to it.
        .accessibilityElement(children: .combine)
      }
    }
  }

  private func criterionRow(_ criterion: ArchitecturePattern.Criterion) -> some View {
    GridRow {
      Text(text(criterion.labelKey))
        .eyebrowStyle()
        .frame(width: labelWidth, alignment: .leading)

      ForEach(patterns) { pattern in
        RichTextView(pattern.answer(to: criterion), font: Typography.secondary)
          .frame(width: columnWidth, alignment: .leading)
      }
    }
  }

  /// A rule across the whole table.
  ///
  /// It is a cell spanning every column rather than a `Divider` dropped between
  /// rows: inside a `Grid`, a view that is not a `GridRow` gets a row of its own
  /// with rules nobody can predict, and the separator ends up as wide as the
  /// first column.
  private var rule: some View {
    GridRow {
      Rectangle()
        .fill(Color.line)
        .frame(height: Tokens.Stroke.hairline)
        .gridCellColumns(columnCount)
        .accessibilityHidden(true)
    }
  }
}
