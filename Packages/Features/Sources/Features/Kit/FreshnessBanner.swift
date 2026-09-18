import Backstage
import DesignSystem
import Domain
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// The banner that admits what is being shown — and, on a tap, says exactly why.
///
/// It appears **only** when there is something to say. A permanent "up to date"
/// notice is a notice people stop reading, and the day it says something else,
/// nobody sees it.
///
/// ## Why a popover and not a sheet
///
/// The question it answers — *where did this come from?* — is a footnote about
/// the thing the reader is looking at. A popover **points at** the banner it
/// belongs to; a sheet covers the screen and severs the connection between the
/// question and what prompted it.
///
/// `presentationCompactAdaptation(.popover)` keeps that on iPhone. Without it,
/// SwiftUI turns every popover into a sheet in a compact size class — which is
/// a reasonable default for a menu and the wrong one for a footnote.
///
/// ## Why it sits in `FeatureKit` and not in `ViewKit`
///
/// Because it carries a backstage annotation, and `Backstage` depends on
/// `ViewKit`. Declaring a `BackstageNote` down there is a module dependency
/// cycle — which the compiler refused, immediately and by name. The straight
/// line `ViewKit → Backstage → FeatureKit` is exactly what makes that mistake
/// impossible to ship rather than merely discouraged.
package struct FreshnessBanner: View {
  private let snapshot: PortfolioSnapshot
  private let language: Language

  @State private var isShowingProvenance = false
  @Chrome private var chrome

  public init(snapshot: PortfolioSnapshot, language: Language) {
    self.snapshot = snapshot
    self.language = language
  }

  public var body: some View {
    if let message = FreshnessStyle(language: language).describe(snapshot.origin) {
      Button {
        isShowingProvenance = true
      } label: {
        HStack(spacing: Tokens.Space.s2) {
          Image(systemName: snapshot.refreshFailure == nil ? "clock" : "wifi.exclamationmark")
            .font(.footnote)
          Text(message)
            .font(Typography.caption)
          Spacer(minLength: 0)
          Image(systemName: "info.circle")
            .font(.footnote)
        }
        .foregroundStyle(Color.ink3)
        .padding(.horizontal, Tokens.Space.s4)
        .padding(.vertical, Tokens.Space.s2)
        .frame(maxWidth: .infinity)
        .background(Color.paper2)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(message)
      .accessibilityHint(chrome.provenanceHint)
      .popover(isPresented: $isShowingProvenance) {
        provenance
          .presentationCompactAdaptation(.popover)
      }
      .backstage(Self.popoverNote)
    }
  }

  private var provenance: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(chrome.provenanceTitle).eyebrowStyle()
      Text(FreshnessStyle(language: language).describe(snapshot.origin) ?? "")
        .font(Typography.secondary)
        .foregroundStyle(Color.ink)
      // The fingerprint, shown rather than hidden: two snapshots with the same
      // version carry the same content whatever their origin, and somebody
      // inspecting this app has every reason to check that for themselves.
      HStack(spacing: Tokens.Space.s2) {
        Text(chrome.provenanceVersion)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
        Text(snapshot.contentVersion)
          .font(Typography.code)
          .foregroundStyle(Color.accent)
          .textSelection(.enabled)
      }
    }
    .padding(Tokens.Space.s5)
    .frame(maxWidth: Tokens.Layout.popoverWidth)
  }

  // ── Backstage ──────────────────────────────────────────────────────────

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
