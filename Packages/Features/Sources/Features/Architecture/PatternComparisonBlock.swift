import Backstage
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

  @Chrome private var chrome

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
      Text(chrome.comparison)
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
        .backstage(Self.gridNote)
      }
      // The table bleeds to the screen edge and insets its content instead of
      // being padded: padding would have clipped the scroll, and the last column
      // would have ended flush against the bezel with nothing to show it was the
      // last one.
      .contentMargins(.horizontal, Tokens.Space.s5, for: .scrollContent)
      .scrollIndicators(.hidden)
    }
  }

  // ── The rows ───────────────────────────────────────────────────────────

  /// The heading of each column: the pattern, and what it pulls apart.
  private var headerRow: some View {
    GridRow {
      Text(chrome.separatesLabel)
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
      Text(chrome.criterion(criterion))
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

  // ── Backstage ──────────────────────────────────────────────────────────

  static let gridNote = BackstageNote(
    id: "architecture.comparison",
    component: "Grid · GridRow",
    role: Bilingual(
      fr: "Aligne quatre motifs sur les mêmes lignes, colonne par colonne.",
      en: "Lines four patterns up on the same rows, column by column."
    ),
    rationale: Bilingual(
      fr: """
        Un tableau ne compare que si « ce qu'il coûte » commence à la même \
        hauteur pour les quatre motifs. `Grid` mesure **toutes** ses cellules \
        avant d'en placer une seule : une colonne prend la largeur de sa cellule \
        la plus large, une ligne la hauteur de sa cellule la plus haute. C'est \
        la définition d'un tableau, et c'est la seule chose qu'un empilement ne \
        sait pas faire.

        L'alignement n'est pas ici une finition : c'est **l'argument**. Dès que \
        les lignes dérivent de quelques points, l'œil cesse de balayer \
        horizontalement et le tableau redevient quatre paragraphes côte à côte.
        """,
      en: """
        A table only compares if “what it costs” starts at the same height for \
        all four patterns. `Grid` measures **every** cell before placing any of \
        them: a column takes the width of its widest cell, a row the height of \
        its tallest. That is the definition of a table, and the one thing a \
        stack cannot do.

        Alignment is not a finish here — it is **the argument**. The moment rows \
        drift by a few points, the eye stops scanning across and the table goes \
        back to being four paragraphs side by side.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Un `LazyVGrid`", en: "A `LazyVGrid`"),
        because: Bilingual(
          fr: "Il pose les cellules à la file : rien n'attache une cellule à sa ligne, donc une cellule haute décale ce qui la suit, pas ses voisines.",
          en: "It flows cells one after another: nothing ties a cell to its row, so a tall cell pushes what follows it rather than its row-mates."
        )
      ),
      .init(
        Bilingual(fr: "Un `VStack` de `HStack`", en: "A `VStack` of `HStack`s"),
        because: Bilingual(
          fr: "Chaque ligne se mesure seule. Les colonnes n'ont alors de commun que la largeur qu'on leur impose à la main, et elle est fausse dès qu'un texte change.",
          en: "Each row measures alone. The columns then share only the width you impose by hand — and it is wrong the moment a sentence changes."
        )
      ),
      .init(
        Bilingual(fr: "Un `Table`", en: "A `Table`"),
        because: Bilingual(
          fr: "C'est une liste de données sélectionnables, et sur iPhone elle se rend en une seule colonne : la comparaison disparaît exactement là où on la lit.",
          en: "It is a list of selectable data rows, and on iPhone it renders as a single column: the comparison vanishes exactly where it is read."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Quand le lecteur compare des valeurs **d'une colonne à l'autre** et que l'alignement porte le sens. Pour un flux d'éléments homogènes — une grille d'applications, des vignettes — `LazyVGrid` est le bon outil, et il est moins cher.",
      en: "When the reader compares values **across columns** and the alignment carries the meaning. For a flow of uniform items — an app grid, thumbnails — `LazyVGrid` is the right tool, and cheaper."
    ),
    pitfall: Bilingual(
      fr: "`Grid` mesure tout : il n'est pas paresseux. Cinq lignes, aucun problème ; mille, autant de vues construites d'un coup. Et un `Divider` posé entre deux `GridRow` n'occupe pas toute la largeur — il faut une cellule qui déclare le nombre de colonnes qu'elle couvre.",
      en: "`Grid` measures everything: it is not lazy. Five rows is nothing; a thousand builds a thousand views at once. And a `Divider` dropped between two `GridRow`s does not span the table — it takes a cell that declares how many columns it covers."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/grid")
  )
}
