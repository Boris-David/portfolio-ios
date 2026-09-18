import Backstage
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The résumé, exactly as the API produces it.
///
/// The app does not **build** a résumé: it displays one, produced once on the
/// server (ADR 0004). Two templates would be two résumés that drift — and it is
/// the one nobody looks at that would end up wrong.
public struct ResumeScreen: View {
  @State private var store: ResumeStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.contentLanguage) private var language
  @Chrome private var chrome

  public init(dependencies: some ResumeDependencies) {
    _store = State(initialValue: ResumeStore(
      reading: dependencies.resume,
      chrome: { AppChrome.for(.french) }
    ))
  }

  public var body: some View {
    NavigationStack {
      Group {
        switch store.phase {
        case .initial, .loading:
          ProgressView(chrome.resumeLoading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let failure):
          FailureView(failure: failure) { Task { await store.load(in: language) } }
        case .loaded(let document):
          PDFPreview(url: document.fileURL)
            .ignoresSafeArea(edges: .bottom)
            .backstage(Self.pdfNote)
        }
      }
      .background(Color.paper2)
      .navigationTitle(chrome.resumeTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(chrome.close) { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
          if case .loaded(let document) = store.phase {
            // `ShareLink` with a **file URL**: that is the file name the
            // recipient will see. Sharing anonymous `Data` would land it under
            // a name the system invented.
            ShareLink(
              item: document.fileURL,
              preview: SharePreview(document.fileName)
            ) {
              Label(chrome.share, systemImage: "square.and.arrow.up")
            }
            .backstage(Self.shareNote)
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        if case .loaded(let document) = store.phase {
          provenance(document)
        }
      }
    }
    .task { await store.load(in: language) }
    .backstageOverlay()
  }

  private func provenance(_ document: ResumeDocument) -> some View {
    HStack(spacing: Tokens.Space.s2) {
      Image(systemName: document.origin == .network ? "arrow.down.circle" : "internaldrive")
        .font(.footnote)
      Text(document.fileName)
        .font(Typography.caption)
        .lineLimit(1)
        .truncationMode(.middle)
      Spacer(minLength: 0)
      if document.entityTag != nil {
        Label(chrome.revalidated, systemImage: "checkmark.seal")
          .font(Typography.caption)
      }
    }
    .foregroundStyle(Color.ink3)
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.vertical, Tokens.Space.s2)
    .background(.bar)
  }

  // ── Coulisses ──────────────────────────────────────────────────────────

  static let pdfNote = BackstageNote(
    id: "resume.pdf",
    component: "PDFKit · PDFView",
    role: Bilingual(
      fr: "Affiche le CV, page par page, avec zoom et défilement natifs.",
      en: "Displays the résumé, page by page, with native zoom and scrolling."
    ),
    rationale: Bilingual(
      fr: """
        **La chaîne complète, de l'API à l'écran :**

        1. la requête part avec l'`ETag` de la version déjà connue — `If-None-Match` ;
        2. le serveur répond `304` si rien n'a changé : **aucun octet de corps** \
           ne traverse le réseau, et on rouvre le fichier déjà sur disque ;
        3. sinon `200`, et `URLSession` écrit le corps dans un fichier \
           temporaire — jamais en mémoire, un PDF n'a pas à y passer ;
        4. le **nom** est lu dans `Content-Disposition`, pas déduit de l'URL : \
           c'est la source qui décide comment son document s'appelle ;
        5. le fichier est déplacé sous ce nom dans le cache, et c'est cette URL \
           que `PDFView` ouvre.

        `PDFView` prend une **URL**. Lui passer les octets marcherait aussi et \
        chargerait tout le document en mémoire ; l'URL laisse PDFKit ne lire que \
        les pages regardées.
        """,
      en: """
        **The full chain, from API to screen:**

        1. the request carries the `ETag` of the version already known — `If-None-Match`;
        2. the server answers `304` when nothing changed: **not one byte of \
           body** crosses the network, and we reopen the file already on disk;
        3. otherwise `200`, and `URLSession` writes the body to a temporary \
           file — never into memory, a PDF has no business there;
        4. the **name** is read from `Content-Disposition`, not derived from the \
           URL: the source decides what its document is called;
        5. the file is moved under that name into the cache, and that URL is \
           what `PDFView` opens.

        `PDFView` takes a **URL**. Handing it bytes would work too and would load \
        the whole document into memory; the URL lets PDFKit read only the pages \
        being looked at.
        """
    ),
    rejected: [
      .init(
        "WKWebView",
        because: Bilingual(
          fr: "affiche un PDF, mais sans miniatures, sans sélection de texte fiable, et en embarquant un moteur web entier pour ça",
          en: "shows a PDF, but with no thumbnails, no reliable text selection, and a whole web engine embedded for it"
        )
      ),
      .init(
        Bilingual(fr: "Rendre le CV dans l'application", en: "Rendering the résumé inside the app"),
        because: Bilingual(
          fr: "deux gabarits, ce sont deux CV qui divergent — et c'est celui qu'on regarde le moins qui devient faux",
          en: "two templates are two résumés that drift — and the one looked at least is the one that goes wrong"
        )
      ),
      .init(
        "QuickLook",
        because: Bilingual(
          fr: "présente en plein écran avec sa propre barre : on perd le partage au bon nom et l'indication de provenance",
          en: "presents full screen with its own bar: you lose sharing under the right name and the provenance line"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        `PDFView` dès qu'il s'agit d'un vrai PDF qu'on veut lire, annoter ou \
        chercher. `QuickLook` pour un aperçu jetable de n'importe quel type de \
        fichier, sans intégration.
        """,
      en: """
        `PDFView` whenever it is a real PDF to read, annotate or search. \
        `QuickLook` for a throwaway preview of any file type, with no \
        integration.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `autoScales` doit être posé **après** l'affectation du document : dans \
        l'autre ordre, PDFKit n'a pas encore de page à mesurer et l'échelle reste \
        à 1 — le CV s'ouvre alors zoomé au coin supérieur gauche.
        """,
      en: """
        `autoScales` must be set **after** assigning the document: the other way \
        round, PDFKit has no page to measure yet and the scale stays at 1 — the \
        résumé then opens zoomed into the top-left corner.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/pdfkit/pdfview")
  )

  static let shareNote = BackstageNote(
    id: "resume.share",
    component: "ShareLink",
    role: Bilingual(
      fr: "Transmet le CV sous son vrai nom de fichier.",
      en: "Sends the résumé under its real file name."
    ),
    rationale: Bilingual(
      fr: """
        Le nom vient de l'en-tête `Content-Disposition` de la réponse, jamais de \
        l'URL. Le site l'a appris à ses dépens : Safari sur iOS **ignore** cet \
        en-tête et nomme un partage d'après le dernier segment de l'URL. Servi \
        sur `/v1/cv/fr.pdf`, le CV arrivait chez le destinataire sous le nom \
        « fr ».

        La correction a porté des deux côtés : l'API sert désormais \
        `/v1/cv/amissan.ag-cv-fr.pdf` **et** l'en-tête. Ici, `ShareLink` reçoit \
        une URL de fichier, donc un nom — pas un blob anonyme.
        """,
      en: """
        The name comes from the response's `Content-Disposition` header, never \
        from the URL. The website learned it the hard way: Safari on iOS \
        **ignores** that header and names a share after the URL's last segment. \
        Served at `/v1/cv/fr.pdf`, the résumé reached recipients named “fr”.

        The fix landed on both sides: the API now serves \
        `/v1/cv/amissan.ag-cv-fr.pdf` **and** the header. Here `ShareLink` gets a \
        file URL, therefore a name — not an anonymous blob.
        """
    ),
    rejected: [
      .init(
        "UIActivityViewController",
        because: Bilingual(
          fr: "c'est ce que `ShareLink` fait déjà, avec en plus l'aperçu et l'adaptation au type d'élément",
          en: "that is what `ShareLink` already does, plus the preview and adaptation to the item type"
        )
      ),
      .init(
        Bilingual(fr: "Partager les `Data` du document", en: "Sharing the document's `Data`"),
        because: Bilingual(
          fr: "un `Data` n'a pas de nom : le système en invente un, du genre « Document »",
          en: "a `Data` has no name: the system invents one, along the lines of “Document”"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        `ShareLink` dès qu'on partage quelque chose de `Transferable` — une URL, \
        une image, un texte. Descendre à `UIActivityViewController` seulement \
        pour des activités personnalisées, qui sont rares.
        """,
      en: """
        `ShareLink` whenever sharing something `Transferable` — a URL, an image, \
        some text. Drop to `UIActivityViewController` only for custom \
        activities, which are rare.
        """
    ),
    pitfall: Bilingual(
      fr: """
        Un fichier partagé depuis le répertoire `Caches` peut être **supprimé par \
        le système** entre le partage et la lecture par l'application \
        destinataire. Pour un document qu'on veut garder, c'est `Documents` — ici \
        il se retélécharge, donc le cache est le bon endroit.
        """,
      en: """
        A file shared from the `Caches` directory can be **purged by the system** \
        between the share and the receiving app reading it. For a document meant \
        to be kept, that is `Documents` — here it re-downloads, so the cache is \
        the right place.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/sharelink")
  )
}
