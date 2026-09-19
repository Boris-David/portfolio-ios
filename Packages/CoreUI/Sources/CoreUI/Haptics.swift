import SwiftUI

/// What the phone should make you feel, said by **meaning**.
///
/// ## Why a vocabulary rather than `UIImpactFeedbackGenerator`
///
/// A generator is fired imperatively: `generator.impactOccurred()`, somewhere in
/// a button's action. Two things go wrong with that, and both are invisible in
/// review.
///
/// It fires on the **intent** rather than on the **result** — you tap, it
/// buzzes, and then the save fails. The feedback lied. And it needs the
/// generator prepared beforehand or the first tap is late, which is the kind of
/// detail that makes an app feel cheap for no reason anyone can name.
///
/// `.sensoryFeedback(_:trigger:)` ties the haptic to a **value that changed**.
/// It cannot fire before the thing happened, because the thing happening is what
/// fires it. It also honours the system's haptics setting for free, which a
/// hand-rolled generator does not.
public enum Feedback: Sendable {
  /// Something finished, and it worked.
  case succeeded
  /// Something finished, and it did not.
  case failed
  /// The value under your finger changed — a picker, a segmented control.
  case selectionChanged
  /// A boundary was reached: the end of a list, a toggle that will not move.
  case reachedLimit

  var sensory: SensoryFeedback {
    switch self {
    case .succeeded: .success
    case .failed: .error
    case .selectionChanged: .selection
    case .reachedLimit: .impact(weight: .light)
    }
  }
}

public extension View {
  /// Plays a haptic when `trigger` changes.
  ///
  /// The `trigger` is the point: pass the **value that changed**, not a counter
  /// you increment by hand. A counter can be incremented before the work
  /// succeeds; a phase cannot.
  func feedback(_ feedback: Feedback, on trigger: some Equatable) -> some View {
    sensoryFeedback(feedback.sensory, trigger: trigger)
  }

  /// Plays a haptic only when the change is one worth feeling.
  ///
  /// Returning `nil` from `decide` means silence. This is how a screen says
  /// "success is worth a buzz, a plain reload is not" without wrapping the
  /// modifier in an `if`, which would change the view's identity and drop its
  /// state.
  func feedback<T: Equatable>(
    on trigger: T,
    decide: @escaping (T, T) -> Feedback?
  ) -> some View {
    sensoryFeedback(trigger: trigger) { old, new in
      decide(old, new)?.sensory
    }
  }
}
