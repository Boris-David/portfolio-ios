import Lottie
import SwiftUI

/// A Lottie vector animation, inside a SwiftUI view.
///
/// ## Why a dependency here, and not for the network
///
/// The rule is the same everywhere in this repository: *a dependency is
/// justified by what would be worse without it, not by what it makes
/// convenient.*
///
/// Without Lottie, you would reimplement an After Effects animation interpreter
/// — interpolated Bézier paths, masks, motion along curves. That is not "less
/// convenient", it is a project of its own. **It would genuinely be worse
/// without.**
///
/// Without Alamofire, you would write… what `URLSession` already does. That
/// would not be worse. Hence one, and not the other.
///
/// ## Why `UIViewRepresentable`
///
/// Lottie does expose a SwiftUI `LottieView`, but fine control of playback —
/// start on appear, stop on disappear, honour reduced motion — goes through
/// UIKit's `AnimationView`. The bridge is forty lines and reads at a glance;
/// working around it would cost more.
public struct LottieAnimationView: UIViewRepresentable {
  private let name: String
  private let bundle: Bundle
  private let loopMode: LottieLoopMode
  private let isPlaying: Bool

  public init(
    _ name: String,
    bundle: Bundle = .designSystem,
    loopMode: LottieLoopMode = .playOnce,
    isPlaying: Bool = true
  ) {
    self.name = name
    self.bundle = bundle
    self.loopMode = loopMode
    self.isPlaying = isPlaying
  }

  public func makeUIView(context: Context) -> Lottie.LottieAnimationView {
    let view = Lottie.LottieAnimationView(name: name, bundle: bundle)
    view.contentMode = .scaleAspectFit
    view.loopMode = loopMode
    view.backgroundBehavior = .pauseAndRestore
    // Without this, the view imposes its intrinsic size and blows up the
    // layout as soon as the animation is bigger than its slot.
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return view
  }

  public func updateUIView(_ view: Lottie.LottieAnimationView, context: Context) {
    // Reduced motion **removes** the animation: it settles on its last frame,
    // which is still a correct image. Damping it would have left motion for
    // somebody who asked for none.
    guard isPlaying, !context.environment.accessibilityReduceMotion else {
      view.currentProgress = 1
      view.pause()
      return
    }
    guard !view.isAnimationPlaying else { return }
    view.play()
  }
}
