import CoreUI
import DesignSystem
import Presentation
import SwiftUI

/// The failure screen — a **dumb view**.
///
/// It receives a cause, an icon and possibly an action — never an `Error`, and
/// never a finished sentence. The wording is read from the catalogue here,
/// because this is the last layer that may: `Presentation` decided **that** the
/// content is unreadable and carried the field path proving it, and could not
/// have written the sentence without a language it has no business holding.
package struct FailureView: View {
  private let failure: PhaseFailure
  private let retry: (() -> Void)?

  @Localized(.interface) private var text
  @State private var appeared = false
  @ReducedMotion private var reducedMotion

  public init(failure: PhaseFailure, retry: (() -> Void)?) {
    self.failure = failure
    self.retry = retry
  }

  public var body: some View {
    VStack(spacing: Tokens.Space.s4) {
      // An animation where there is one, a symbol where there is not.
      //
      // The two failures worth animating are the ones a reader may sit in for a
      // while — no route, nothing stored. A malformed payload is a developer's
      // problem and gets a still symbol: animating it would dress up a defect.
      if let animation = failure.icon.animation {
        LottieAnimation(animation)
          .frame(width: Tokens.Icon.hero * 3, height: Tokens.Icon.hero * 3)
          .accessibilityHidden(true)
      } else {
        Image(failure.icon)
          .font(.system(size: Tokens.Icon.hero, weight: .light))
          .foregroundStyle(Color.ink3)
          // The symbol breathes once on appearance — enough to catch the eye,
          // not enough to distract from what there is to read.
          .symbolEffect(.bounce, value: appeared)
      }

      VStack(spacing: Tokens.Space.s2) {
        Text(text(failure.titleKey))
          .font(Typography.heading)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.center)
          // ⚠️ Without this the title is **truncated** rather than wrapped, and
          // only at the accessibility text sizes: "Contenu illisible" came out
          // as "Contenu illi…". The message below always had it; the title did
          // not, which is how this survives review — the two lines look alike.
          //
          // Found on the first correct run of `Scripts/screens.sh`. The previous
          // runs had captured that axis at the wrong size and shown nothing.
          .fixedSize(horizontal: false, vertical: true)
        Text(failure.message(text))
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      // No button when retrying would change nothing: offering a useless
      // action is a promise that will not be kept.
      if failure.isRetryable, let retry {
        Button(text(InterfaceText.retry), action: retry)
          .buttonStyle(.adaptiveGlassProminent)
          .padding(.top, Tokens.Space.s2)
      }
    }
    .padding(Tokens.Space.s6)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(text(failure.titleKey)). \(failure.message(text))")
    .task {
      guard !reducedMotion else { return }
      appeared = true
    }
  }
}

// The previews build the failure from a **cause**, exactly as the application
// does. Handing the view two ready-made sentences would have previewed a state
// the app can never produce.

#Preview("Unreachable") {
  FailureView(failure: PhaseFailure(.unreachable), retry: {})
    .background(Color.paper)
}

#Preview("Unreadable — no retry") {
  FailureView(
    failure: PhaseFailure(.malformed(path: "profile.headline", reason: .missingField)),
    retry: nil
  )
  .background(Color.paper)
}

#Preview("Nothing at all") {
  FailureView(failure: PhaseFailure(.nothingAvailable), retry: {})
    .background(Color.paper)
}
