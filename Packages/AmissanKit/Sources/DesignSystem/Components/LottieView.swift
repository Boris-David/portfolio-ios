import Lottie
import SwiftUI

/// Une animation vectorielle Lottie, dans une vue SwiftUI.
///
/// ## Pourquoi une dépendance ici, et pas pour le réseau
///
/// La règle est la même partout dans ce dépôt : *une dépendance se justifie par
/// ce qui serait pire sans elle, pas par ce qu'elle rend pratique.*
///
/// Sans Lottie, il faudrait réimplémenter un interpréteur d'animations After
/// Effects — des tracés de Bézier interpolés, des masques, des trajectoires.
/// Ce n'est pas « moins pratique », c'est un projet à soi seul. **Ce serait
/// réellement pire sans.**
///
/// Sans Alamofire, il faudrait écrire… ce qu'`URLSession` fait déjà. Ce ne
/// serait pas pire. D'où l'un, et pas l'autre.
///
/// ## Pourquoi `UIViewRepresentable`
///
/// Lottie expose bien un `LottieView` SwiftUI, mais le contrôle fin de la
/// lecture — démarrer à l'apparition, s'arrêter à la disparition, respecter le
/// mouvement réduit — passe par l'`AnimationView` d'UIKit. Le pont est de
/// quarante lignes et se lit d'un coup ; le contourner coûterait plus cher.
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
    // Sans ça, la vue impose sa taille intrinsèque et fait exploser la mise en
    // page dès que l'animation est plus grande que sa place.
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return view
  }

  public func updateUIView(_ view: Lottie.LottieAnimationView, context: Context) {
    // Le mouvement réduit **supprime** l'animation : elle se fige sur sa
    // dernière image, qui reste une image juste. L'atténuer aurait laissé du
    // mouvement à qui a demandé qu'il n'y en ait plus.
    guard isPlaying, !context.environment.accessibilityReduceMotion else {
      view.currentProgress = 1
      view.pause()
      return
    }
    guard !view.isAnimationPlaying else { return }
    view.play()
  }
}
