import SwiftUI

/// L'apparition d'un bloc à l'arrivée à l'écran.
///
/// ## Deux règles qui ne se négocient pas
///
/// **Rien n'est illisible au repos.** L'état initial n'est masqué que si
/// l'animation peut réellement jouer. Une vue qui resterait à `opacity: 0` parce
/// qu'un observateur ne s'est jamais déclenché est du contenu perdu — et c'est
/// le défaut le plus fréquent de ce motif.
///
/// **Le premier écran n'est pas animé.** Une apparition en fondu sur ce qu'on
/// voit en ouvrant retarde la première information de quelques centaines de
/// millisecondes. C'est exactement ce qu'un recruteur qui parcourt ne pardonne
/// pas.
public struct Reveal: ViewModifier {
  private let delay: Double
  @State private var isVisible = false
  @ReducedMotion private var reducedMotion

  public init(delay: Double = 0) {
    self.delay = delay
  }

  public func body(content: Content) -> some View {
    content
      .opacity(shouldHide ? 0 : 1)
      .offset(y: shouldHide ? 14 : 0)
      .onScrollVisibilityChange(threshold: 0.08) { visible in
        guard visible, !isVisible else { return }
        withAnimation(Motion.entrance.delay(delay)) { isVisible = true }
      }
      // Filet de sécurité : si la vue n'entre jamais dans une zone défilable —
      // un aperçu, un écran court, un test — elle s'affiche quand même.
      .task {
        try? await Task.sleep(for: .milliseconds(600))
        if !isVisible { withAnimation(Motion.entrance) { isVisible = true } }
      }
  }

  private var shouldHide: Bool {
    !isVisible && !reducedMotion
  }
}

public extension View {
  /// Apparaît en montant légèrement, une fois, à l'entrée à l'écran.
  func reveal(delay: Double = 0) -> some View {
    modifier(Reveal(delay: delay))
  }
}
