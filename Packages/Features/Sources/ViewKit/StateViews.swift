import DesignSystem
import Domain
import Presentation
import SwiftUI

/// Ce que l'écran montre pendant qu'il n'a rien à montrer.
///
/// Un squelette plutôt qu'un rond qui tourne : il occupe la place que le
/// contenu prendra, donc rien ne saute quand il arrive. Un indicateur centré
/// laisse la page vide, puis la remplit d'un coup — et ce saut se voit.
public struct LoadingSkeleton: View {
  @State private var shimmer = false
  @ReducedMotion private var reducedMotion
  @Chrome private var chrome

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
    .accessibilityLabel(chrome.loading)
    .onAppear {
      guard !reducedMotion else { return }
      withAnimation(.easeInOut(duration: Tokens.Duration.shimmer).repeatForever(autoreverses: true)) {
        shimmer = true
      }
    }
  }
}

/// Le bandeau qui avoue ce qu'on affiche.
///
/// Il n'apparaît **que** lorsqu'il y a quelque chose à dire. Une mention « à
/// jour » permanente est une mention qu'on cesse de lire, et le jour où elle
/// change personne ne la voit.
public struct FreshnessBanner: View {
  private let snapshot: PortfolioSnapshot
  private let language: Language

  public init(snapshot: PortfolioSnapshot, language: Language) {
    self.snapshot = snapshot
    self.language = language
  }

  public var body: some View {
    if let message = FreshnessStyle(language: language).describe(snapshot.origin) {
      HStack(spacing: Tokens.Space.s2) {
        Image(systemName: snapshot.refreshFailure == nil ? "clock" : "wifi.exclamationmark")
          .font(.footnote)
        Text(message)
          .font(Typography.caption)
        Spacer(minLength: 0)
      }
      .foregroundStyle(Color.ink3)
      .padding(.horizontal, Tokens.Space.s4)
      .padding(.vertical, Tokens.Space.s2)
      .frame(maxWidth: .infinity)
      .background(Color.paper2)
      .accessibilityElement(children: .combine)
    }
  }
}
