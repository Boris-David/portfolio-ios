import CoreUI
import Decisions
import DesignSystem
import Domain
import Presentation
import SwiftUI
import UIKit
import ViewKit

/// One production app, as a cell.
///
/// ## Why it lives in the shared kit
///
/// It used to sit in `WorkScreen.swift`, because that was the only screen that
/// drew apps. Two do now — the profile opens on a shelf of them, the work tab
/// holds the full grid — and they are sibling modules that cannot import each
/// other. A cell copied into both is two cells that will drift; one of them
/// would keep the share action and the other would not.

package struct AppCell: View {
  package let app: ProductionApp
  @Environment(\.openURL) private var openURL
  @Environment(ToastCenter.self) private var toasts
  @Localized(.interface) private var text

  package init(app: ProductionApp) { self.app = app }

  /// Where the card sends the reader: the store listing when there is one, the
  /// public repository otherwise. The content guarantees one of the two, so a
  /// `nil` here is a contract violation and not a state to design for — the
  /// button simply does nothing rather than the cell pretending it is tappable.
  private var destination: URL? {
    (app.appStoreURL ?? app.sourceURL).flatMap(URL.init(string:))
  }

  package var body: some View {
    Button {
      if let destination { openURL(destination) }
    } label: {
      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        AppIconView(slug: app.slug)
        Text(app.name)
          .font(Typography.bodyStrong)
          .foregroundStyle(Color.ink)
          .lineLimit(1)
        Text(app.territory)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s3)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .fill(Color.paper2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular)
      )
    }
    .buttonStyle(.pressableCard)
    // Secondary actions, out of the way until asked for.
    //
    // A long press on a card is the iOS idiom for "what else can I do with
    // this". Putting a share button on thirty-three cards would have doubled the
    // grid's visual weight for something almost nobody wants — and the one
    // person who does already knows where to look.
    .contextMenu {
      if let destination {
        ShareLink(item: destination) {
          Label(text(InterfaceText.share), icon: .share)
        }
        Button {
          UIPasteboard.general.url = destination
          toasts.show(text(InterfaceText.linkCopied), kind: .succeeded, icon: .succeeded)
        } label: {
          Label(text(InterfaceText.copyLink), icon: .link)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(app.name), \(app.territory)")
    .accessibilityHint(text(InterfaceText.openInAppStore))
    .decision(KitDecisions.contextMenu)
  }
}

/// An app's icon, named by its **public slug**.
///
/// Never by an internal network identifier: those do not leave the building, and
/// an image path is public content just as much as a sentence is.
package struct AppIconView: View {
  package let slug: String

  package init(slug: String) { self.slug = slug }

  package var body: some View {
    ContentImage(slug, kind: .appIcon)
      .frame(width: Tokens.Layout.appIconSide, height: Tokens.Layout.appIconSide)
      .clipShape(RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)
  }
}
