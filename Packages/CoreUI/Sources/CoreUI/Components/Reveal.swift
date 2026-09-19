import DesignSystem
import SwiftUI

/// A block appearing as it reaches the screen.
///
/// ## Two rules that are not negotiable
///
/// **Nothing is unreadable at rest.** The initial state is hidden only if the
/// animation can genuinely play. A view left at `opacity: 0` because an observer
/// never fired is lost content — and it is this pattern's most frequent defect.
///
/// **The first screen is not animated.** A fade-in on what you see when you open
/// the app delays the first piece of information by a few hundred milliseconds.
/// That is exactly what a skimming recruiter does not forgive.
struct Reveal: ViewModifier {
  private let delay: Double
  @State private var isVisible = false
  @ReducedMotion private var reducedMotion

  init(delay: Double = 0) {
    self.delay = delay
  }

  func body(content: Content) -> some View {
    content
      .opacity(shouldHide ? 0 : 1)
      .offset(y: shouldHide ? 14 : 0)
      .onScrollVisibilityChange(threshold: 0.08) { visible in
        guard visible, !isVisible else { return }
        withAnimation(Motion.entrance.delay(delay)) { isVisible = true }
      }
      // Safety net: if the view never enters a scrollable area — a preview, a
      // short screen, a test — it shows anyway.
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
  /// Appears rising slightly, once, on entering the screen.
  func reveal(delay: Double = 0) -> some View {
    modifier(Reveal(delay: delay))
  }
}
