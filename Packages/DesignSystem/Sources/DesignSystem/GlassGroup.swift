import SwiftUI

/// Groups several glass surfaces so they blend into each other.
///
/// Without a container, two glass buttons side by side are two **stacked**
/// panes: the background is sampled twice and the rendering darkens where they
/// intersect. The container merges them into one layer.
///
/// On iOS 18 it does nothing an `HStack` would not — and that is exactly what is
/// wanted: the shape of the code does not change from one version to the other.
public struct GlassGroup<Content: View>: View {
  private let spacing: CGFloat
  private let content: Content

  public init(spacing: CGFloat = Tokens.Space.s2, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: spacing) { content }
    } else {
      content
    }
  }
}
