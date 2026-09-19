import CoreUI
import DesignSystem
import Presentation
import SwiftUI
import ViewKit

/// The way into a long reading — the engineering record, the pattern
/// comparison.
///
/// `NavigationLink(value:)` and not `NavigationLink(destination:)`: this row
/// declares **where it goes**, and the tab's root decides what that means. The
/// screen it opens lives in a sibling module this one cannot import — and that
/// is the point, not an obstacle worked around.
///
/// It takes its words rather than resolving them, because two features use it
/// now and each names its own destination.
package struct ReadingLinkRow: View {
  private let route: Route
  private let title: String
  private let summary: String

  package init(route: Route, title: String, summary: String) {
    self.route = route
    self.title = title
    self.summary = summary
  }

  package var body: some View {
    NavigationLink(value: route) {
      Surface {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
          VStack(alignment: .leading, spacing: Tokens.Space.s1) {
            Text(title)
              .font(Typography.heading)
              .foregroundStyle(Color.ink)
              .multilineTextAlignment(.leading)
            Text(summary)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)
          }
          Spacer(minLength: Tokens.Space.s2)
          Image(systemName: "chevron.right")
            .font(.system(size: Tokens.Icon.caption, weight: .semibold))
            .foregroundStyle(Color.ink3)
        }
      }
    }
    // A card style, not `.plain`: plain would give the whole card the accent
    // colour and the summary would stop reading as body text.
    .buttonStyle(.pressableCard)
  }
}
