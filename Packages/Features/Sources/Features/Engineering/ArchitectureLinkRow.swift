import CoreUI
import DesignSystem
import Presentation
import SwiftUI
import ViewKit

/// The way into the architecture comparison.
///
/// `NavigationLink(value:)` and not `NavigationLink(destination:)`: this row
/// declares **where it goes**, and the tab's root decides what that means. The
/// screen it opens lives in a sibling module this one cannot import — and that
/// is the point, not an obstacle worked around.
struct ArchitectureLinkRow: View {
  @Localized(.interface) private var text

  var body: some View {
    NavigationLink(value: Route.architectures) {
      Surface {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
          VStack(alignment: .leading, spacing: Tokens.Space.s1) {
            Text(text(InterfaceText.architecturePatterns))
              .font(Typography.heading)
              .foregroundStyle(Color.ink)
              .multilineTextAlignment(.leading)
            Text(text(InterfaceText.architecturePatternsSummary))
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
    // `.plain`, or the whole card takes the accent colour and the summary stops
    // being readable as body text.
    .buttonStyle(.pressableCard)
    .padding(.horizontal, Tokens.Space.s5)
  }
}
