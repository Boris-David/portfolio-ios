import Backstage
import Domain
import Foundation

/// The backstage annotations for the Architecture screens.
///
/// ## Why the content left the view files
///
/// Because that is what it is: **content**. `ProfileBlocks.swift` was 524 lines,
/// of which 330 were bilingual prose about why a component was chosen — a view
/// file whose majority was not a view.
///
/// Stated plainly by the author: *"changing a piece of text should not mean
/// touching the code of a view or a screen."* It should not, and now it does
/// not. A screen says `.backstage(ArchitectureNotes.hero)`; what that note says
/// lives here, and editing it never reopens a `body`.
///
/// ## Why this is not a string catalogue
///
/// A `.xcstrings` catalogue follows the **device's** language. This app's
/// displayed language follows the **content** the source serves, and the two
/// have disagreed on screen before — French tabs above English text, on the very
/// first launch. `Bilingual` carries both versions in one declaration, two lines
/// apart, and a missing translation is a **compile error** rather than a silent
/// fallback to the key.
enum ArchitectureNotes {
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
