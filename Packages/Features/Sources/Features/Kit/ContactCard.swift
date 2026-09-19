import CoreUI
import DesignSystem
import Domain
import Presentation
import SwiftUI
import ViewKit

/// The one published contact channel — written once, shown in two places.
///
/// ## Why it moved here
///
/// It existed twice: as a block at the foot of the profile and as a sheet of
/// its own, in two sibling modules that cannot import each other. Two renderings
/// of one piece of content, and they had **already diverged** — the sheet drew
/// an envelope and a generic link glyph for every row, the block picked a glyph
/// per service. Neither was wrong; they simply were not the same, and nothing
/// would ever have said so.
///
/// One component, two hosts. The card decides what a contact looks like; the
/// hosts decide where it sits.
package struct ContactCard: View {
  private let contact: Profile.Contact

  @Environment(\.openURL) private var openURL

  package init(contact: Profile.Contact) {
    self.contact = contact
  }

  package var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(contact.title)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)

      Text(contact.body)
        .font(Typography.body)
        .foregroundStyle(Color.ink2)
        .fixedSize(horizontal: false, vertical: true)

      Button {
        open("mailto:\(contact.email)")
      } label: {
        Label(contact.email, icon: .contact)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.adaptiveGlassProminent)

      WrappingRow {
        ForEach(contact.links) { link in
          Button {
            open(link.url)
          } label: {
            Label(link.label, systemImage: symbol(for: link.id))
              .font(Typography.secondary)
          }
          .buttonStyle(.adaptiveGlass)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func open(_ string: String) {
    guard let url = URL(string: string) else { return }
    openURL(url)
  }

  /// SF Symbols does not cover brands: GitHub and LinkedIn are not in it.
  /// Rather than embedding logos — whose use their owners govern — a generic
  /// symbol is used, and the **label** carries the identification.
  private func symbol(for id: String) -> String {
    switch id {
    case "github": "chevron.left.forwardslash.chevron.right"
    case "linkedin": "person.2"
    default: "link"
    }
  }
}
