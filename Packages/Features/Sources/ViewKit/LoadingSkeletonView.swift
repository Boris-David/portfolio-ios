import DesignSystem
import Domain
import Presentation
import SwiftUI

/// What the screen shows while it has nothing to show.
///
/// A skeleton rather than a spinner: it occupies the room the content will take,
/// so nothing jumps when it arrives. A centred indicator leaves the page empty
/// and then fills it all at once — and that jump is visible.
package struct LoadingSkeletonView: View {
  @State private var shimmer = false
  @ReducedMotion private var reducedMotion
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      ForEach(0..<4, id: \.self) { index in
        RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
          .fill(Color.paper2)
          .frame(height: index == 0 ? 120 : 64)
          .opacity(shimmer ? Tokens.Opacity.shimmer : 1)
      }
    }
    .padding(Tokens.Space.s5)
    .accessibilityElement()
    .accessibilityLabel(text(InterfaceText.loading))
    .onAppear {
      guard !reducedMotion else { return }
      withAnimation(.easeInOut(duration: Tokens.Duration.shimmer).repeatForever(autoreverses: true)) {
        shimmer = true
      }
    }
  }
}
