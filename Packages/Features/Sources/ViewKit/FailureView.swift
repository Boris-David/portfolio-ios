import DesignSystem
import Presentation
import SwiftUI

/// The failure screen — a **dumb view**.
///
/// It knows neither the domain, nor the store, nor what failed: it receives a
/// title, a sentence, an icon, and possibly an action. That is what lets it be
/// previewed in four variants without wiring anything up.
package struct FailureView: View {
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
      Image(failure.icon)
        .font(.system(size: Tokens.Icon.hero, weight: .light))
        .foregroundStyle(Color.ink3)
        // The symbol breathes once on appearance — enough to catch the eye,
        // not enough to distract from what there is to read.
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

      // No button when retrying would change nothing: offering a useless
      // action is a promise that will not be kept.
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

#Preview("Unreachable") {
  FailureView(
    failure: PhaseFailure(
      title: "Contenu indisponible",
      message: "La source n'a pas répondu, et rien n'est enregistré sur cet appareil.",
      icon: .offline,
      isRetryable: true
    ),
    retry: {}
  )
  .background(Color.paper)
}

#Preview("Unreadable — no retry") {
  FailureView(
    failure: PhaseFailure(
      title: "Contenu illisible",
      message: "La source a répondu quelque chose d'inattendu en « profile.headline ».",
      icon: .malformed,
      isRetryable: false
    ),
    retry: nil
  )
  .background(Color.paper)
}
