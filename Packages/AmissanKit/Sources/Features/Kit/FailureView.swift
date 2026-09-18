import DesignSystem
import SwiftUI

/// L'écran d'erreur — une **vue bête**.
///
/// Elle ne connaît ni le domaine, ni le store, ni ce qui a échoué : elle reçoit
/// un titre, une phrase, un symbole, et éventuellement une action. C'est ce qui
/// lui permet d'être prévisualisée en quatre variantes sans monter quoi que ce
/// soit.
public struct FailureView: View {
  private let failure: PhaseFailure
  private let retry: (() -> Void)?

  @Chrome private var chrome
  @State private var appeared = false
  @ReducedMotion private var reducedMotion

  public init(failure: PhaseFailure, retry: (() -> Void)?) {
    self.failure = failure
    self.retry = retry
  }

  public var body: some View {
    VStack(spacing: Tokens.Space.s4) {
      Image(systemName: failure.symbol)
        .font(.system(size: Tokens.Icon.hero, weight: .light))
        .foregroundStyle(Color.ink3)
        // Le symbole respire une fois à l'apparition — assez pour attirer l'œil,
        // pas assez pour distraire de ce qu'il y a à lire.
        .symbolEffect(.bounce, value: appeared)

      VStack(spacing: Tokens.Space.s2) {
        Text(failure.title)
          .font(Typography.heading)
          .foregroundStyle(Color.ink)
        Text(failure.message)
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      // Pas de bouton quand réessayer ne changerait rien : proposer une action
      // inutile est une promesse qu'on ne tient pas.
      if failure.isRetryable, let retry {
        Button(chrome.retry, action: retry)
          .buttonStyle(.adaptiveGlassProminent)
          .padding(.top, Tokens.Space.s2)
      }
    }
    .padding(Tokens.Space.s6)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(failure.title). \(failure.message)")
    .task {
      guard !reducedMotion else { return }
      appeared = true
    }
  }
}

#Preview("Injoignable") {
  FailureView(
    failure: PhaseFailure(
      title: "Contenu indisponible",
      message: "La source n'a pas répondu, et rien n'est enregistré sur cet appareil.",
      symbol: "wifi.slash",
      isRetryable: true
    ),
    retry: {}
  )
  .background(Color.paper)
}

#Preview("Illisible — sans réessai") {
  FailureView(
    failure: PhaseFailure(
      title: "Contenu illisible",
      message: "La source a répondu quelque chose d'inattendu en « profile.headline ».",
      symbol: "exclamationmark.triangle",
      isRetryable: false
    ),
    retry: nil
  )
  .background(Color.paper)
}
