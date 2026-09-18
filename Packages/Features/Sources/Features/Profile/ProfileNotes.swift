import Backstage
import Domain
import Foundation

/// The backstage annotations for the Profile screens.
///
/// ## Why the content left the view files
///
/// Because that is what it is: **content**. `ProfileBlocks.swift` was 524 lines,
/// of which 330 were bilingual prose about why a component was chosen — a view
/// file whose majority was not a view.
///
/// Stated plainly by the author: *"changing a piece of text should not mean
/// touching the code of a view or a screen."* It should not, and now it does
/// not. A screen says `.backstage(ProfileNotes.hero)`; what that note says
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
enum ProfileNotes {
  static let heroNote = BackstageNote(
    id: "profile.hero",
    component: "ZStack · ViewThatFits",
    role: Bilingual(
      fr: "L'ouverture : un monogramme, un nom, une action.",
      en: "The opening: a monogram, a name, one action."
    ),
    rationale: Bilingual(
      fr: """
        La version précédente était une **page d'accueil web** : pastille verte \
        à point, trois lignes à icônes, deux boutons côte à côte. Ce vocabulaire \
        sert à vendre quelque chose à quelqu'un qui arrive froid.

        Une application s'ouvre autrement. Qui l'a lancée a déjà décidé de \
        regarder : le premier écran lui doit une **identité**, pas un argumentaire.

        `ZStack` porte trois couches qui se **chevauchent** vraiment — un halo \
        qui déborde de la colonne de lecture, le contenu, la zone sûre. \
        `ViewThatFits` mesure au lieu de comparer à un seuil : aux tailles \
        d'accessibilité, le monogramme passe au-dessus du nom tout seul.
        """,
      en: """
        The previous version was a **web landing page**: green-dotted pill, \
        three icon rows, two buttons side by side. That vocabulary exists to \
        sell something to somebody who arrived cold.

        An app opens differently. Whoever launched it already decided to look: \
        the first screen owes them an **identity**, not a pitch.

        `ZStack` carries three layers that genuinely **overlap** — a wash \
        bleeding past the reading column, the content, the safe area. \
        `ViewThatFits` measures rather than comparing against a threshold \
        somebody guessed: at the accessibility sizes the monogram moves above \
        the name on its own.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une photo", en: "A portrait photograph"),
        because: Bilingual(
          fr: "Plusieurs pays déconseillent explicitement la photo sur un CV : elle invite un jugement qui n'a rien à voir avec le travail. Le monogramme donne le même point d'ancrage.",
          en: "Several countries' hiring guidance advises against a CV photo: it invites a judgement that has nothing to do with the work. The monogram gives the same anchor."
        )
      ),
      .init(
        Bilingual(fr: "Deux boutons côte à côte", en: "Two buttons side by side"),
        because: Bilingual(
          fr: "Demander de choisir avant d'avoir rien lu. Le CV est désormais dans la barre d'outils de **tous** les écrans : plus trouvable, et moins bruyant.",
          en: "It asks the reader to choose before they have read anything. The résumé is now a toolbar item on **every** screen: more findable, and quieter."
        )
      ),
      .init(
        Bilingual(fr: "Un seuil de `sizeCategory`", en: "A `sizeCategory` threshold"),
        because: Bilingual(
          fr: "Un seuil est une supposition sur une largeur. `ViewThatFits` mesure la vraie.",
          en: "A threshold is a guess about a width. `ViewThatFits` measures the real one."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "`ZStack` quand les couches se chevauchent réellement — sinon c'est un `VStack` déguisé. `ViewThatFits` quand deux dispositions sont également valides et que seule la place tranche.",
      en: "`ZStack` when the layers genuinely overlap — otherwise it is a `VStack` in disguise. `ViewThatFits` when two arrangements are equally valid and only the room decides."
    ),
    pitfall: Bilingual(
      fr: "Un dégradé décoratif dans un `ZStack` intercepte les touches par défaut : sans `allowsHitTesting(false)`, il avale les taps destinés au bouton qu'il recouvre.",
      en: "A decorative gradient in a `ZStack` intercepts touches by default: without `allowsHitTesting(false)` it swallows taps meant for the button underneath."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/viewthatfits")
  )

  static let actionNote = BackstageNote(
    id: "profile.action",
    component: "Button · adaptiveGlassProminent",
    role: Bilingual(
      fr: "L'unique action principale de l'écran d'ouverture.",
      en: "The opening screen's one primary action."
    ),
    rationale: Bilingual(
      fr: """
        Une action principale par écran, au plus. Deux boutons de même poids ne \
        sont pas deux fois plus utiles : ils annulent la hiérarchie et le lecteur \
        doit arbitrer à la place du concepteur.

        Le style se rend différemment sur les deux mondes — verre teinté sur \
        iOS 26, aplat d'accent sur iOS 18 — parce que la même teinte à faible \
        opacité sur un matériau translucide donne du blanc sur du pâle en thème \
        clair. Mesuré à l'écran, pas supposé.
        """,
      en: """
        One primary action per screen, at most. Two buttons of equal weight are \
        not twice as useful: they cancel the hierarchy, and the reader ends up \
        arbitrating in the designer's place.

        The style renders differently in the two worlds — tinted glass on \
        iOS 26, a solid accent fill on iOS 18 — because the same tint at low \
        opacity over a translucent material gives white on pale in light theme. \
        Measured on screen, not assumed.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`.borderedProminent`", en: "`.borderedProminent`"),
        because: Bilingual(
          fr: "Il ignore Liquid Glass sur iOS 26 : le bouton aurait l'air d'iOS 17 au milieu d'une barre en verre.",
          en: "It ignores Liquid Glass on iOS 26: the button would look like iOS 17 in the middle of a glass bar."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "L'action que l'écran existe pour proposer. S'il y en a deux, l'une des deux n'en est pas une.",
      en: "The action the screen exists to offer. If there are two, one of them is not one."
    ),
    pitfall: Bilingual(
      fr: "`glassEffect` s'applique à la vue, jamais en arrière-plan : posé dans un `.background`, il **recouvre** le libellé et le bouton paraît vide.",
      en: "`glassEffect` applies to the view, never as a background: put in `.background`, it **covers** the label and the button looks empty."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/buttonstyle")
  )

  static let scrollView = BackstageNote(
    id: "profile.scrollview",
    component: "ScrollView + refreshable",
    role: Bilingual(
      fr: "Porte tout l'écran d'accueil et son geste de rafraîchissement.",
      en: "Carries the whole home screen and its pull-to-refresh gesture."
    ),
    rationale: Bilingual(
      fr: """
        `.refreshable` branche le geste système sur une fonction `async`, et \
        **attend qu'elle se termine** pour retirer l'indicateur. C'est ce qui \
        rend le retour honnête : l'utilisateur voit tourner tant que le réseau \
        travaille, pas une demi-seconde arbitraire.
        """,
      en: """
        `.refreshable` wires the system gesture to an `async` function and \
        **waits for it to finish** before removing the spinner. That is what \
        makes the feedback honest: it spins while the network works, not for \
        an arbitrary half second.
        """
    ),
    rejected: [
      .init(
        "List",
        because: Bilingual(
          fr: "impose ses marges, ses séparateurs et son fond ; ici la mise en page est éditoriale, pas tabulaire",
          en: "imposes its own insets, separators and background; the layout here is editorial, not tabular"
        )
      ),
      .init(
        Bilingual(fr: "Un bouton « Recharger »", en: "A “Reload” button"),
        because: Bilingual(
          fr: "le geste de tirer est déjà connu de tout le monde, un bouton en plus occuperait la place d'un contenu",
          en: "everyone already knows the pull gesture; an extra button would take the place of content"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        `ScrollView` dès que la mise en page est libre. `List` quand les \
        éléments sont homogènes, nombreux, et qu'on veut le recyclage de \
        cellules, le glissement latéral et la sélection.
        """,
      en: """
        `ScrollView` whenever the layout is free-form. `List` when rows are \
        homogeneous and numerous, and you want cell reuse, swipe actions and \
        selection.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `.refreshable` ne fonctionne **que** s'il est posé sur la vue \
        défilable elle-même ou l'un de ses ancêtres directs. Placé sur un \
        enfant, il ne remonte pas — et ne produit aucun avertissement.
        """,
      en: """
        `.refreshable` only works when applied to the scrollable view itself \
        or one of its direct ancestors. On a child it simply does not \
        propagate — and warns about nothing.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/refreshable(action:)")
  )

  static let metrics = BackstageNote(
    id: "profile.metrics",
    component: "contentTransition(.numericText())",
    role: Bilingual(
      fr: "Fait défiler les chiffres qui se comptent, sans que la tuile tremble.",
      en: "Rolls the counting figures without the tile jittering."
    ),
    rationale: Bilingual(
      fr: """
        Un nombre qui change de valeur change aussi de **largeur** : les \
        chiffres n'ont pas tous la même. Sans précaution, la tuile tremble \
        pendant tout le décompte.

        Deux modificateurs y répondent ensemble. `.monospacedDigit()` fige la \
        largeur de chaque chiffre ; `.contentTransition(.numericText())` \
        demande au système d'interpoler les glyphes plutôt que de les \
        remplacer, ce qui donne le défilement mécanique d'un compteur.

        Et le décompte n'est pas décidé ici : c'est un champ du contenu. \
        « ~5 M » **pourrait** se compter — on choisit que non, parce \
        qu'animer une approximation lui donne une précision qu'elle n'a pas.
        """,
      en: """
        A number that changes value also changes **width**: digits are not \
        all the same size. Left alone, the tile jitters through the whole \
        count.

        Two modifiers answer this together. `.monospacedDigit()` fixes each \
        digit's width; `.contentTransition(.numericText())` asks the system \
        to interpolate glyphs rather than replace them, which gives the \
        mechanical roll of an odometer.

        And the counting is not decided here: it is a content field. “~5 M” \
        **could** count up — we choose not to, because animating an \
        approximation lends it a precision it does not have.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Un `Timer` qui incrémente", en: "A `Timer` that increments"),
        because: Bilingual(
          fr: "il tourne à sa propre cadence, indépendante du rafraîchissement de l'écran — le décompte saute sur un appareil chargé",
          en: "it runs at its own cadence, independent of the display refresh — the count stutters on a busy device"
        )
      ),
      .init(
        Bilingual(fr: "Animer la valeur sans `monospacedDigit`", en: "Animating the value without `monospacedDigit`"),
        because: Bilingual(
          fr: "la largeur change à chaque image et tout le bloc se décale",
          en: "the width changes every frame and the whole block shifts"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Dès qu'un nombre change **à l'écran** et que la transition doit se \
        voir : un score, un compteur, un prix. Pour un nombre statique, ces \
        deux modificateurs ne coûtent rien mais n'apportent rien.
        """,
      en: """
        Whenever a number changes **on screen** and the transition should be \
        seen: a score, a counter, a price. For a static number, both \
        modifiers cost nothing and add nothing.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)")
  )
}
