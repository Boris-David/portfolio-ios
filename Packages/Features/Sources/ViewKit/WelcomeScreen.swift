import CoreUI
import DesignSystem
import Domain
import Presentation
import SwiftUI

/// What the reader sees while the first load happens.
///
/// ## Why it exists
///
/// Because what they saw before was **nothing**. The system's launch image
/// disappears the moment SwiftUI draws its first frame, and that frame was the
/// `initial` phase, which renders `Color.clear` on purpose — the screen has
/// just appeared and is not waiting yet. Then a skeleton, then the content.
/// A cold start therefore opened on a blank page for as long as the fetch
/// took, and a blank page is read as an app that has not started.
///
/// ## Why it says the name last and not first
///
/// Nothing in this repository writes a fact — the name, the role, the figures
/// all come from the API, which is the invariant the whole content design rests
/// on. So the greeting is an interface word, and the identity appears **when it
/// arrives**, a beat before the app does. That turns the constraint into the
/// nicest part: the screen fills in as the content lands, instead of standing
/// still while it does.
///
/// ## Why a floor and not a delay
///
/// It stays for at least `Tokens.Duration.welcome` so it cannot flash and be
/// gone — a splash that appears for 200 ms reads as a glitch. It adds nothing
/// beyond that: if the content is already there when the floor expires, the
/// app appears. It never waits *for its own sake*.
public struct WelcomeScreen: View {
  private let profile: Profile?

  @ReducedMotion private var reducedMotion
  @Localized(.interface) private var text

  public init(profile: Profile?) {
    self.profile = profile
  }

  public var body: some View {
    ZStack {
      Color.paper.ignoresSafeArea()

      VStack(spacing: Tokens.Space.s4) {
        Text(text(InterfaceText.welcome))
          .font(Typography.hero)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        // Decorative in the accessibility sense: VoiceOver has nothing to say
        // about a stroke being drawn, so it is hidden rather than announced as
        // "image".
        LottieAnimation(LottieCatalogue.signature)
          .frame(height: Tokens.Layout.signatureHeight)
          .frame(maxWidth: Tokens.Layout.signatureWidth)
          .accessibilityHidden(true)

        if let profile {
          VStack(spacing: Tokens.Space.s1) {
            Text(profile.name.display)
              .font(Typography.title)
              .foregroundStyle(Color.ink)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
            Text(profile.headline)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
          .transition(.opacity.combined(with: .offset(y: reducedMotion ? 0 : 8)))
          .accessibilityElement(children: .combine)
        }
      }
      .padding(.horizontal, Tokens.Space.s5)
      .animation(reducedMotion ? nil : Motion.entrance, value: profile != nil)
    }
    .accessibilityAddTraits(.isHeader)
  }
}
