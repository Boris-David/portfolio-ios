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
  @Environment(ToastCenter.self) private var toasts
  @Localized(.interface) private var text

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
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(text(InterfaceText.close)) { dismiss() }
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
      .safeAreaInset(edge: .bottom) {
        if case .loaded(let document) = store.phase {
          provenance(document)
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
    .onChange(of: store.phase.isLoaded) { was, now in
      guard now, !was else { return }
      toasts.show(text(InterfaceText.resumeReady), kind: .succeeded, icon: .succeeded)
    }
    .decisionOverlay()
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
        Label(text(InterfaceText.revalidated), systemImage: "checkmark.seal")
          .font(Typography.caption)
      }
    }
    .foregroundStyle(Color.ink3)
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.vertical, Tokens.Space.s2)
    .background(.bar)
  }

  // ── Decisions ──────────────────────────────────────────────────────────

}
