import Backstage
import Domain
import Foundation

/// The backstage annotations for the Work screens.
///
/// ## Why the content left the view files
///
/// Because that is what it is: **content**. `ProfileBlocks.swift` was 524 lines,
/// of which 330 were bilingual prose about why a component was chosen — a view
/// file whose majority was not a view.
///
/// Stated plainly by the author: *"changing a piece of text should not mean
/// touching the code of a view or a screen."* It should not, and now it does
/// not. A screen says `.backstage(WorkNotes.hero)`; what that note says
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
enum WorkNotes {
  static let gridNote = BackstageNote(
    id: "work.grid",
    component: "LazyVGrid · GridItem(.adaptive)",
    role: Bilingual(
      fr: "Dispose les applications en colonnes qui s'adaptent à la largeur.",
      en: "Lays the apps out in columns that adapt to the available width."
    ),
    rationale: Bilingual(
      fr: """
        `.adaptive(minimum:)` laisse **le système** choisir le nombre de \
        colonnes selon la place : deux sur un iPhone compact, trois sur un Pro \
        Max, davantage sur un iPad. Une seule déclaration couvre toutes les \
        tailles, et surtout toutes les tailles de **texte** — en accessibilité \
        extra-large, la grille retombe à une colonne toute seule.

        `Lazy` compte ici : les cellules ne sont créées qu'en approchant de \
        l'écran. Avec trente-trois entrées portant chacune une image, tout \
        construire d'un coup se verrait au premier défilement.
        """,
      en: """
        `.adaptive(minimum:)` lets **the system** pick the column count from the \
        space available: two on a compact iPhone, three on a Pro Max, more on an \
        iPad. One declaration covers every size — and above all every **text** \
        size: at accessibility extra-large the grid falls back to one column on \
        its own.

        `Lazy` matters here: cells are only built as they approach the screen. \
        With thirty-three entries each carrying an image, building them all at \
        once would show on the first scroll.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`.fixed()` ou un nombre de colonnes codé en dur", en: "`.fixed()` or a hard-coded column count"),
        because: Bilingual(
          fr: "il faudrait une valeur par classe de taille, et elles seraient toutes fausses en accessibilité extra-large",
          en: "it would need one value per size class, and all of them would be wrong at accessibility extra-large"
        )
      ),
      .init(
        Bilingual(fr: "`VGrid` non paresseux", en: "A non-lazy `VGrid`"),
        because: Bilingual(
          fr: "trente-trois cellules et leurs images construites d'un coup, pour deux visibles",
          en: "thirty-three cells and their images built at once, for two on screen"
        )
      ),
      .init(
        Bilingual(fr: "Un `List`", en: "A `List`"),
        because: Bilingual(
          fr: "une ligne par application donnerait trois écrans de défilement là où la grille montre l'échelle d'un coup d'œil — et l'échelle est l'information",
          en: "one row per app would take three screens of scrolling where the grid shows the scale at a glance — and the scale is the information"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        `.adaptive` dès que le nombre de colonnes n'est pas une décision \
        éditoriale mais une conséquence de la place. `.flexible` quand le nombre \
        de colonnes **est** la décision — une comparaison à deux colonnes, par \
        exemple.
        """,
      en: """
        `.adaptive` whenever the column count is not an editorial decision but a \
        consequence of available space. `.flexible` when the column count **is** \
        the decision — a two-column comparison, for instance.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `minimum:` est la largeur minimale d'une **colonne**, espacement non \
        compris. Une valeur trop basse produit six colonnes illisibles sur iPad \
        sans qu'aucune contrainte ne s'en plaigne.
        """,
      en: """
        `minimum:` is the minimum width of a **column**, spacing excluded. Too \
        low a value produces six unreadable columns on iPad without any \
        constraint complaining.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/griditem")
  )

  static let contextMenuNote = BackstageNote(
    id: "work.contextmenu",
    component: "contextMenu · ShareLink",
    role: Bilingual(
      fr: "Partager ou copier le lien App Store d'une application, sans encombrer la grille.",
      en: "Share or copy an app's App Store link, without cluttering the grid."
    ),
    rationale: Bilingual(
      fr: """
        Un appui long sur une carte est l'idiome iOS de « qu'est-ce que je peux \\
        faire d'autre avec ça ». Poser un bouton de partage sur trente-trois \\
        cartes aurait doublé le poids visuel de la grille pour ce que presque \\
        personne ne cherche — et celui qui le cherche sait déjà où regarder.
        """,
      en: """
        A long press on a card is the iOS idiom for "what else can I do with \\
        this". Putting a share button on thirty-three cards would have doubled \\
        the grid's visual weight for something almost nobody wants — and the one \\
        person who does already knows where to look.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Un bouton de partage sur chaque carte", en: "A share button on every card"),
        because: Bilingual(
          fr: "Trente-trois boutons pour une action secondaire : la grille cesse d'être une grille.",
          en: "Thirty-three buttons for a secondary action: the grid stops being a grid."
        )
      ),
      .init(
        Bilingual(fr: "Un balayage latéral", en: "A swipe action"),
        because: Bilingual(
          fr: "Réservé aux lignes de liste. Sur une grille, il n'existe pas et personne ne le cherche.",
          en: "Reserved for list rows. On a grid it does not exist, and nobody looks for it."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Des actions secondaires sur un élément identifiable. Jamais pour l'action principale : un menu contextuel ne se découvre pas.",
      en: "Secondary actions on an identifiable item. Never for the primary action: a context menu is not discoverable."
    ),
    pitfall: Bilingual(
      fr: "Le menu **remplace** l'aperçu de la vue : une carte au fond transparent y apparaît sans son fond, et paraît cassée.",
      en: "The menu **replaces** the view's preview: a card with a transparent background shows up without it, and looks broken."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:)")
  )

  static let disclosureNote = BackstageNote(
    id: "work.disclosure",
    component: "Dépliage sur mesure · clipped",
    role: Bilingual(
      fr: "Déplie un chantier sans faire sauter la mise en page autour de lui.",
      en: "Expands a workstream without making the surrounding layout jump."
    ),
    rationale: Bilingual(
      fr: """
        Le dépliage anime une **hauteur**, et c'est le cas le plus piégeux de \
        SwiftUI : animer `frame(height:)` demande de connaître la hauteur finale \
        avant de l'afficher, ce qu'on ne sait pas d'un texte de longueur \
        variable.

        La solution ici est de laisser le contenu **exister** en permanence et \
        de n'animer que ce qui est mesurable : opacité et hauteur nulle, sous un \
        `.clipped()`. La hauteur réelle est laissée à SwiftUI, qui l'interpole \
        dès lors que le changement est dans une `withAnimation`.

        Conséquence heureuse : le texte replié est **dans l'arbre de vues**. La \
        recherche système le trouve, et VoiceOver peut l'atteindre.
        """,
      en: """
        Expansion animates a **height**, the trickiest case in SwiftUI: \
        animating `frame(height:)` requires knowing the final height before \
        showing it, which you cannot know for text of variable length.

        The answer here is to let the content **exist** at all times and animate \
        only what is measurable: opacity and a zero height, under a \
        `.clipped()`. The real height is left to SwiftUI, which interpolates it \
        as long as the change happens inside `withAnimation`.

        A happy consequence: the collapsed text is **in the view tree**. System \
        search finds it, and VoiceOver can reach it.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`DisclosureGroup` natif", en: "The built-in `DisclosureGroup`"),
        because: Bilingual(
          fr: "son chevron, ses marges et son animation ne se redéfinissent pas assez pour tenir le design, et son étiquette n'accepte pas de mise en page libre",
          en: "its chevron, insets and animation cannot be redefined enough to hold the design, and its label does not take a free-form layout"
        )
      ),
      .init(
        Bilingual(fr: "Ajouter et retirer la vue de l'arbre", en: "Adding and removing the view from the tree"),
        because: Bilingual(
          fr: "le contenu replié disparaît de la recherche et de VoiceOver, et la transition part de rien — donc elle saute",
          en: "collapsed content disappears from search and VoiceOver, and the transition starts from nothing — so it jumps"
        )
      ),
      .init(
        Bilingual(fr: "Animer `frame(height:)` mesuré par `GeometryReader`", en: "Animating `frame(height:)` measured by `GeometryReader`"),
        because: Bilingual(
          fr: "une mesure par image, un aller-retour de mise en page à chaque fois, et un saut au premier affichage avant que la mesure n'existe",
          en: "one measurement per frame, a layout round trip each time, and a jump on first display before the measurement exists"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Ce motif dès qu'un bloc de **hauteur inconnue** doit s'ouvrir et se \
        fermer. Si la hauteur est connue et fixe, animer `frame` directement est \
        plus simple et parfaitement correct.
        """,
      en: """
        This pattern whenever a block of **unknown height** must open and close. \
        If the height is known and fixed, animating `frame` directly is simpler \
        and perfectly correct.
        """
    ),
    pitfall: Bilingual(
      fr: """
        Sans `.clipped()`, le contenu replié **déborde** de son conteneur pendant \
        l'animation et passe par-dessus les cartes voisines. On ne le voit que \
        sur un appareil lent, ou en enregistrant l'écran au ralenti.
        """,
      en: """
        Without `.clipped()`, collapsed content **overflows** its container \
        during the animation and paints over neighbouring cards. You only see it \
        on a slow device, or by recording the screen in slow motion.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/disclosuregroup")
  )
}
