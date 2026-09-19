import Decisions
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
  @Environment(ResumeStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Localized(.interface) private var text

  @State private var isShowingProvenance = false

  public init() {}

  public var body: some View {
    NavigationStack {
      Group {
        switch store.phase {
        case .initial, .loading:
          // `.pulse` on the symbol rather than a bare spinner: it says *this
          // particular thing* is on its way, where a spinner says only that
          // something is. The label says which.
          VStack(spacing: Tokens.Space.s4) {
            Image(Icon.resume)
              .font(.system(size: Tokens.Icon.hero, weight: .light))
              .foregroundStyle(Color.ink3)
              .symbolEffect(.pulse)
            Text(text(InterfaceText.resumeLoading))
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityElement(children: .combine)
          .accessibilityLabel(text(InterfaceText.resumeLoading))
        case .failed(let failure):
          FailureView(failure: failure) { Task { await store.load() } }
        case .loaded(let document):
          PDFPreview(url: document.fileURL)
            .ignoresSafeArea(edges: .bottom)
            .decision(ResumeDecisions.pdf)
        }
      }
      .background(Color.paper2)
      .navigationTitle(text(InterfaceText.resumeTitle))
      // The one fact about this document the reader cannot work out for
      // themselves and might be surprised by: which language it came in. The
      // store has always known; nothing ever said it.
      //
      // It is **also** in the provenance popover, because iOS 18 has no
      // subtitle slot — see `navigationDetail`.
      .navigationDetail(LanguageStyle(language: store.language).endonym)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(text(InterfaceText.close)) { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
          if case .loaded(let document) = store.phase {
            provenanceButton(document)
          }
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
              Label(text(InterfaceText.share), systemImage: "square.and.arrow.up")
            }
            .decision(ResumeDecisions.share)
          }
        }
      }
    }
    .task { await store.load() }
    // The confirmation fires on the **phase**, not on the tap that started the
    // download: a haptic tied to the intent would buzz before the document had
    // arrived, and lie the day it never does.
    .feedback(on: store.phase.isLoaded) { was, now in
      now && !was ? .succeeded : nil
    }
    // ⚠️ No "resume ready" toast. There was one, and it was drawn by the toast
    // layer of the scene — which is **under** this cover. It announced the
    // arrival of a document the reader was already looking at, behind the
    // document itself. The haptic above is the confirmation; the document
    // appearing is the rest of it.
    // Same reason as the settings sheet: a cover is its own presentation
    // context, and the scene's anchor cannot reach over it.
    .decisionSheet()
  }

  /// ⚠️ This was a **permanent bar** across the bottom of the résumé, carrying
  /// the file name, the cache origin and a "revalidated" seal.
  ///
  /// All three are engineering sawdust shown to the reader. Somebody who opened
  /// a CV is reading a CV; whether it arrived over the network or came out of a
  /// cache, and whether an `ETag` matched, answers a question they did not ask
  /// — while taking a strip off the document they did.
  ///
  /// It is not deleted, because it is genuinely worth having: this app claims
  /// its content is served and verifiable, and somebody inspecting that claim
  /// has every reason to check. It moved behind an ⓘ, which is exactly what a
  /// footnote is.
  private func provenanceButton(_ document: ResumeDocument) -> some View {
    Button { isShowingProvenance = true } label: {
      Image(systemName: "info.circle")
    }
    .accessibilityLabel(text(InterfaceText.provenanceTitle))
    .popover(isPresented: $isShowingProvenance) {
      provenance(document)
        // A popover **points at** the control it belongs to; a sheet covers the
        // screen and severs the connection between the question and what
        // prompted it. Without this, SwiftUI turns every popover into a sheet
        // in a compact size class.
        .presentationCompactAdaptation(.popover)
    }
  }

  private func provenance(_ document: ResumeDocument) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(text(InterfaceText.provenanceTitle)).eyebrowStyle()

      // The language again, in full, because iOS 18 has no navigation subtitle
      // and this is then the only place that says it.
      Label(
        LanguageStyle(language: store.language).endonym,
        icon: .language
      )
      .font(Typography.secondary)
      .foregroundStyle(Color.ink)

      Label {
        Text(document.fileName)
          .lineLimit(1)
          .truncationMode(.middle)
      } icon: {
        Image(systemName: document.origin == .network ? "arrow.down.circle" : "internaldrive")
      }
      .font(Typography.caption)
      .foregroundStyle(Color.ink3)

      if document.entityTag != nil {
        Label(text(InterfaceText.revalidated), systemImage: "checkmark.seal")
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
      }
    }
    .padding(Tokens.Space.s5)
    .frame(maxWidth: Tokens.Layout.popoverWidth, alignment: .leading)
  }

  // ── Decisions ──────────────────────────────────────────────────────────

}
