import CoreUI
import DesignSystem
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The contact sheet.
///
/// ## Why it is a feature and not a corner of the root
///
/// It used to live inside `AppRoot.swift`, which is how a composition root
/// quietly becomes a screen file. It is a screen: it reads the store, it
/// renders, it opens URLs. Everything a screen does.
///
/// ## What it stopped doing itself
///
/// Two things, and both were the only place in the app that did them.
///
/// It **drew its own contact**, so the same content existed here and at the
/// foot of the profile — and the two had already drifted on which glyph each
/// link carries. The card is now one component; this screen decides only that
/// it is presented as a sheet.
///
/// And it was the only screen not going through `PhaseView`: an `if let` and a
/// hand-written skeleton, which meant a failed load showed a skeleton for ever
/// instead of a failure with a retry. Nine screens shared one switch; this one
/// had a tenth of its own.
///
/// ## Why a medium detent
///
/// There is one address and a short list of links. A sheet sized to its content
/// keeps the screen underneath in view, which is what tells the reader they have
/// not left the page they were on.
public struct ContactScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    NavigationStack {
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        ScrollView {
          ContactCard(contact: snapshot.portfolio.profile.contact)
            .padding(Tokens.Space.s5)
        }
      }
      .background(Color.paper)
      .navigationTitle(text(InterfaceText.contactTitle))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(text(InterfaceText.close)) { dismiss() }
        }
      }
    }
    // Medium by default, and expandable — not medium only. At the accessibility
    // text sizes the address and the links no longer fit in half a screen, and
    // a sheet that can only be scrolled inside a fixed window is the one place
    // a reader cannot make room.
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}
