import DesignSystem
import Presentation
import SwiftUI

/// Renders the four phases, and the transitions between them.
///
/// Written **once**. No screen rewrites this `switch`: that is what guarantees
/// they all behave the same — same skeleton, same transition, same error screen
/// — and that adding a case later happens in one place.
///
/// The transition matters as much as the states. Going from `loading` to
/// `loaded` with no transition makes the page jump; a cross-fade with a slight
/// rise gives the impression the content **arrives**, which is exactly what is
/// happening.
package struct PhaseView<Value: Sendable, Content: View, Skeleton: View>: View {
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
        // Nothing. The screen has just appeared: it is not waiting yet.
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

  /// The animation fires on the **crossing** between "nothing to show" and
  /// "something to show", not on the value itself: content that changes without
  /// changing phase must not replay an entrance.
  private var isPending: Bool { phase.isPending }
}

package extension PhaseView where Skeleton == LoadingSkeletonView {
  /// The design system's default skeleton.
  init(
    _ phase: ViewPhase<Value>,
    retry: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Value) -> Content
  ) {
    self.init(phase, retry: retry, skeleton: { LoadingSkeletonView() }, content: content)
  }
}
