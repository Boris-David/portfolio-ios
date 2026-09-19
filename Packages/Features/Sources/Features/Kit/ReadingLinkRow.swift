import CoreUI
import DesignSystem
import Presentation
import SwiftUI
import ViewKit

/// The way into a long reading — the engineering record, the pattern
/// comparison.
///
/// It declares **where it goes**, and the section's shell decides what that
/// means — a push, or a presentation when the stack is already deep. The screen
/// it opens lives in a sibling module this one cannot import, and that is the
/// point rather than an obstacle worked around.
///
/// ⚠️ A `Button` and not a `NavigationLink(value:)`. A link appends to the path
/// and that is the whole of its behaviour: it cannot be told "push unless it
/// would be the third". See `OpenRouteAction`.
///
/// It takes its words rather than resolving them, because two features use it
/// now and each names its own destination.
package struct ReadingLinkRow: View {
  @Environment(\.openRoute) private var openRoute

  private let route: Route
  private let title: String
  private let summary: String

  package init(route: Route, title: String, summary: String) {
    self.route = route
    self.title = title
    self.summary = summary
  }

  package var body: some View {
    Button { openRoute(route) } label: {
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
