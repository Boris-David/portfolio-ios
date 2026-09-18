import DesignSystem
import SwiftUI

/// Rend les quatre phases, et les transitions entre elles.
///
/// Écrit **une fois**. Aucun écran ne réécrit ce `switch` : c'est ce qui garantit
/// qu'ils se comportent tous pareil — même squelette, même transition, même
/// écran d'erreur — et qu'ajouter un cas plus tard se fait à un seul endroit.
///
/// La transition compte autant que les états. Passer de `loading` à `loaded`
/// sans transition fait sauter la page ; un fondu croisé avec une légère montée
/// donne l'impression que le contenu **arrive**, ce qui est exactement ce qui se
/// passe.
public struct PhaseView<Value: Sendable, Content: View, Skeleton: View>: View {
  private let phase: ViewPhase<Value>
  private let retry: (() -> Void)?
  private let skeleton: () -> Skeleton
  private let content: (Value) -> Content

  @ReducedMotion private var reducedMotion

  public init(
    _ phase: ViewPhase<Value>,
    retry: (() -> Void)? = nil,
    @ViewBuilder skeleton: @escaping () -> Skeleton,
    @ViewBuilder content: @escaping (Value) -> Content
  ) {
    self.phase = phase
    self.retry = retry
    self.skeleton = skeleton
    self.content = content
  }

  public var body: some View {
    ZStack {
      switch phase {
      case .initial:
        // Rien. L'écran vient d'apparaître : il n'attend pas encore.
        Color.clear
      case .loading:
        skeleton()
          .transition(.opacity)
      case .loaded(let value):
        content(value)
          .transition(.opacity.combined(with: .offset(y: reducedMotion ? 0 : 8)))
      case .failed(let failure):
        FailureView(failure: failure, retry: retry)
          .transition(.opacity)
      }
    }
    .animation(reducedMotion ? nil : Motion.entrance, value: isPending)
  }

  /// L'animation se déclenche sur le **passage** entre « rien à montrer » et
  /// « quelque chose à montrer », pas sur la valeur elle-même : un contenu qui
  /// change sans changer de phase ne doit pas rejouer une apparition.
  private var isPending: Bool { phase.isPending }
}

public extension PhaseView where Skeleton == LoadingSkeleton {
  /// Le squelette par défaut du design system.
  init(
    _ phase: ViewPhase<Value>,
    retry: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Value) -> Content
  ) {
    self.init(phase, retry: retry, skeleton: { LoadingSkeleton() }, content: content)
  }
}
