import CoreUI
import DesignSystem
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
/// ## Why a medium detent and not a full sheet
///
/// There is one address and a short list of links. A sheet sized to its content
/// keeps the screen underneath in view, which is what tells the reader they have
/// not left the page they were on.
public struct ContactScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    NavigationStack {
      Group {
        if let contact = store.portfolio?.profile.contact {
          ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.s4) {
              Text(contact.title)
                .font(Typography.title)
                .foregroundStyle(Color.ink)

              Text(contact.body)
                .font(Typography.body)
                .foregroundStyle(Color.ink2)
                .fixedSize(horizontal: false, vertical: true)

              Button {
                open("mailto:\(contact.email)")
              } label: {
                Label(contact.email, systemImage: "envelope")
              }
              .buttonStyle(.adaptiveGlassProminent)

              ForEach(contact.links) { link in
                Button {
                  open(link.url)
                } label: {
                  Label(link.label, systemImage: "link")
                }
                .buttonStyle(.adaptiveGlass)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.s5)
          }
        } else {
          LoadingSkeletonView()
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
    // Medium by default, and expandable — not medium only. At the
    // accessibility text sizes the address and three links no longer fit in
    // half a screen, and a sheet that can only be scrolled inside a fixed
    // window is the one place a reader cannot make room.
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func open(_ string: String) {
    guard let url = URL(string: string) else { return }
    openURL(url)
  }
}
