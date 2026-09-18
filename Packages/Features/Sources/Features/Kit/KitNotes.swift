import Backstage
import Domain
import Foundation

/// The backstage annotations for the Kit screens.
///
/// ## Why the content left the view files
///
/// Because that is what it is: **content**. `ProfileBlocks.swift` was 524 lines,
/// of which 330 were bilingual prose about why a component was chosen — a view
/// file whose majority was not a view.
///
/// Stated plainly by the author: *"changing a piece of text should not mean
/// touching the code of a view or a screen."* It should not, and now it does
/// not. A screen says `.backstage(KitNotes.hero)`; what that note says
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
enum KitNotes {
  static let popoverNote = BackstageNote(
    id: "shared.freshness",
    component: "popover · presentationCompactAdaptation",
    role: Bilingual(
      fr: "Dit d'où vient le contenu affiché, et depuis quand.",
      en: "Says where the content on screen came from, and how old it is."
    ),
    rationale: Bilingual(
      fr: """
        La question — *d'où ça vient ?* — est une **note de bas de page** sur ce \
        qu'on est en train de lire. Un popover **pointe** le bandeau auquel il \
        se rapporte ; une feuille couvre l'écran et coupe le lien entre la \
        question et ce qui l'a provoquée.

        `presentationCompactAdaptation(.popover)` le maintient sur iPhone. Sans \
        ça, SwiftUI transforme tout popover en feuille en classe de taille \
        compacte — un défaut raisonnable pour un menu, le mauvais pour une note.
        """,
      en: """
        The question — *where did this come from?* — is a **footnote** about \
        what the reader is looking at. A popover **points at** the banner it \
        belongs to; a sheet covers the screen and severs the connection between \
        the question and what prompted it.

        `presentationCompactAdaptation(.popover)` keeps that on iPhone. Without \
        it, SwiftUI turns every popover into a sheet in a compact size class — a \
        reasonable default for a menu, the wrong one for a footnote.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une `sheet` à mi-hauteur", en: "A half-height `sheet`"),
        because: Bilingual(
          fr: "Elle couvre le contenu dont on demande justement la provenance.",
          en: "It covers the very content whose provenance is being asked about."
        )
      ),
      .init(
        Bilingual(fr: "Tout afficher dans le bandeau", en: "Showing everything in the banner"),
        because: Bilingual(
          fr: "Une empreinte de contenu en permanence sur chaque écran est du bruit pour tout le monde sauf une personne par an.",
          en: "A content fingerprint permanently on every screen is noise for everybody except one person a year."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Une information courte rattachée à un élément précis. Jamais pour une tâche : un popover se ferme au premier toucher à côté.",
      en: "A short piece of information attached to a precise element. Never for a task: a popover dismisses on the first tap outside it."
    ),
    pitfall: Bilingual(
      fr: "Sans `presentationCompactAdaptation`, il devient une feuille sur iPhone — et la moitié de la raison de l'employer disparaît sans prévenir.",
      en: "Without `presentationCompactAdaptation` it becomes a sheet on iPhone — and half the reason for using one disappears with no warning."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/presentationcompactadaptation(_:)")
  )
}
