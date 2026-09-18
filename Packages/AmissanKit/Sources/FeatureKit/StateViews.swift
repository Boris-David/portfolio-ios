import DesignSystem
import Domain
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
          .opacity(shimmer ? 0.55 : 1)
      }
    }
    .padding(Tokens.Space.s5)
    .accessibilityElement()
    .accessibilityLabel(chrome.loading)
    .onAppear {
      guard !reducedMotion else { return }
      withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
        shimmer = true
      }
    }
  }
}

/// L'écran plein d'erreur — le seul cas où il n'y a **rien** à afficher.
public struct ContentUnavailableScreen: View {
  private let failure: ContentUnavailable
  private let retry: () -> Void
  @Chrome private var chrome

  public init(failure: ContentUnavailable, retry: @escaping () -> Void) {
    self.failure = failure
    self.retry = retry
  }

  public var body: some View {
    ContentUnavailableView {
      Label(title, systemImage: symbol)
    } description: {
      Text(message)
    } actions: {
      Button(chrome.retry, action: retry)
        .buttonStyle(.adaptiveGlassProminent)
    }
    .background(Color.paper)
  }

  private var title: String {
    switch failure {
    case .unreachable, .nothingAvailable: chrome.unavailableTitle
    case .malformed: chrome.unreadableTitle
    }
  }

  private var symbol: String {
    switch failure {
    case .unreachable, .nothingAvailable: "wifi.slash"
    case .malformed: "exclamationmark.triangle"
    }
  }

  /// Un message dit **ce qui s'est passé et quoi faire**. Pas d'excuse, pas de
  /// « une erreur est survenue » — qui n'apprend rien à personne.
  private var message: String {
    switch failure {
    case .unreachable: chrome.unreachableMessage
    case .nothingAvailable: chrome.nothingAvailableMessage
    case .malformed(let path, let reason):
      // Le chemin exact est affiché : c'est une application de portfolio, et
      // quelqu'un qui la regarde a tout intérêt à voir le diagnostic réel
      // plutôt qu'un message enrobé.
      chrome.malformedMessage(path: path, reason: reason)
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
