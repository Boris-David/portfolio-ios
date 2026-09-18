import Backstage
import Domain
import Foundation

/// The backstage annotations for the Journey screens.
///
/// ## Why the content left the view files
///
/// Because that is what it is: **content**. `ProfileBlocks.swift` was 524 lines,
/// of which 330 were bilingual prose about why a component was chosen — a view
/// file whose majority was not a view.
///
/// Stated plainly by the author: *"changing a piece of text should not mean
/// touching the code of a view or a screen."* It should not, and now it does
/// not. A screen says `.backstage(JourneyNotes.hero)`; what that note says
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
enum JourneyNotes {
  static let timelineNote = BackstageNote(
    id: "journey.timeline",
    component: "DateFormatter · shortMonthSymbols",
    role: Bilingual(
      fr: "Transforme « 2023-05 » en « mai 2023 », dans la langue affichée.",
      en: "Turns “2023-05” into “May 2023”, in the language on screen."
    ),
    rationale: Bilingual(
      fr: """
        La source sert des dates **machine** : `start: "2023-05"`, `end: null`. \
        Elle ne sert jamais « mai 2023 → aujourd'hui », et c'est délibéré — la \
        chaîne lisible dépend de la langue, du contexte et de la place, et la \
        figer à la source la figerait pour le site, le CV en PDF et cette \
        application à la fois.

        Un seul détail ne s'obtient pas directement : le **point d'abréviation**. \
        Le français le porte déjà (« janv. »), l'anglais non (« Jan »), et \
        « mai » comme « May » n'en prennent aucun puisqu'ils ne sont pas abrégés. \
        D'où une règle unique pour les deux langues : *une forme courte qui \
        diffère de la forme longue est une abréviation, et une abréviation prend \
        un point.*

        C'est exactement la règle du site, qui l'obtient d'`Intl`. Les deux \
        plateformes affichent donc la même chaîne — pas « à peu près la même ».
        """,
      en: """
        The source serves **machine** dates: `start: "2023-05"`, `end: null`. It \
        never serves “May 2023 → today”, and that is deliberate — the readable \
        string depends on language, context and available width, and fixing it \
        at the source would fix it for the site, the PDF résumé and this app at \
        once.

        One detail is not available directly: the **abbreviation period**. \
        French already carries it (“janv.”), English does not (“Jan”), and \
        “mai” like “May” take none since they are not abbreviated. Hence a \
        single rule for both languages: *a short form that differs from the long \
        form is an abbreviation, and an abbreviation takes a period.*

        It is exactly the site's rule, which gets it from `Intl`. Both platforms \
        therefore print the same string — not “roughly the same”.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une table de mois par langue", en: "A month table per language"),
        because: Bilingual(
          fr: "douze entrées × deux langues à tenir, et une faute d'abréviation ne se voit qu'en production",
          en: "twelve entries × two languages to maintain, and an abbreviation mistake only shows in production"
        )
      ),
      .init(
        Bilingual(fr: "Servir la chaîne déjà formatée depuis l'API", en: "Serving a pre-formatted string from the API"),
        because: Bilingual(
          fr: "elle deviendrait la même pour le PDF, le site et l'app — et aucun des trois n'a la même place",
          en: "it would be the same for the PDF, the site and the app — and none of the three has the same room"
        )
      ),
      .init(
        Bilingual(fr: "`Date` plutôt que `YearMonth`", en: "`Date` rather than `YearMonth`"),
        because: Bilingual(
          fr: "une `Date` porte une heure et un fuseau : « mai 2023 » devient avril 2023 quelque part sur la planète",
          en: "a `Date` carries a time and a zone: “May 2023” becomes April 2023 somewhere on the planet"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Dès qu'une date doit s'afficher : toujours par un formateur localisé, \
        jamais par concaténation. Et dans le modèle, le type le plus **grossier** \
        qui suffise — une date de diplôme n'a pas besoin de secondes.
        """,
      en: """
        Whenever a date is displayed: always through a localised formatter, never \
        by concatenation. And in the model, the **coarsest** type that suffices — \
        a graduation date has no need for seconds.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `DateFormatter` est coûteux à construire et n'est pas `Sendable`. En \
        créer un par cellule de liste se mesure au défilement ; ici il vit dans \
        une valeur créée une fois par écran.
        """,
      en: """
        `DateFormatter` is expensive to build and is not `Sendable`. Creating one \
        per list cell is measurable while scrolling; here it lives in a value \
        created once per screen.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/foundation/dateformatter")
  )
}
