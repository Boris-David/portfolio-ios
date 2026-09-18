import Backstage
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// L'écran d'accueil : qui il est, en trois secondes.
///
/// L'ordre de lecture est décidé, pas subi — disponibilité, nom, métier, puis
/// les chiffres, puis l'appel à l'action. Un recruteur **parcourt** ; ce qui
/// compte doit se trouver sans défiler.
public struct ProfileScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Chrome private var chrome

  public init() {}

  public var body: some View {
    SectionShell(title: chrome.tabProfile) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot)
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────

  private func content(_ snapshot: PortfolioSnapshot) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        FreshnessBanner(snapshot: snapshot, language: store.language)
        HeroBlock(profile: snapshot.portfolio.profile)
        MetricsBlock(metrics: snapshot.portfolio.metrics)
        ExpertiseBlock(
          section: snapshot.portfolio.section("depth"),
          topics: snapshot.portfolio.expertise
        )
        ContactBlock(contact: snapshot.portfolio.profile.contact)
      }
      .padding(.bottom, Tokens.Space.s8)
      .readableWidth()
    }
    // Tirer pour rafraîchir : le geste attendu, et il attend vraiment la fin —
    // un indicateur qui disparaît avant l'arrivée du contenu donne l'impression
    // que le geste n'a rien fait.
    .refreshable { await store.refresh() }
    .backstage(
      BackstageNote(
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
    )
  }
}
