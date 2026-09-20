import Foundation
import Observation

/// Decides **what** is announced, and for how long. It draws nothing.
///
/// ## Why the state holder is here and the view is not
///
/// Same line as everywhere else in this layer: choosing to announce something,
/// wording it, and deciding when it stops being relevant are decisions. Drawing
/// a rounded rectangle is not.
///
/// The practical payoff is that the awkward parts are testable with values: a
/// second toast arriving while the first is up, a dismissal racing the timer,
/// a toast cancelled because the screen went away. None of that needs a
/// renderer, and none of it is observable in a snapshot test.
///
/// ## Why a monotonically increasing id
///
/// Two identical messages in a row are two events. With the message as identity,
/// SwiftUI would consider the second one the same view, keep it on screen, and
/// never restart the animation or the timer — so the second "Copied" would look
/// like nothing happened. The counter makes them distinct by construction.
@Observable
@MainActor
public final class ToastCenter {
  public private(set) var current: Toast?

  private var nextID = 0
  private var dismissal: Task<Void, Never>?
  private let duration: Duration

  /// - Parameter duration: how long a toast stays. Injected so a test does not
  ///   have to wait three seconds to prove that it leaves.
  public init(duration: Duration = .seconds(3)) {
    self.duration = duration
  }

  /// Announces something. A toast already on screen is **replaced**, not queued.
  ///
  /// Queueing would mean the reader sees a message about something that happened
  /// several seconds ago, possibly after the screen changed. The most recent
  /// fact is the only one still worth showing.
  public func show(_ message: String, kind: Toast.Kind = .informed, icon: Icon) {
    nextID += 1
    current = Toast(id: nextID, message: message, kind: kind, icon: icon)

    dismissal?.cancel()
    dismissal = Task { [duration] in
      try? await Task.sleep(for: duration)
      guard !Task.isCancelled else { return }
      current = nil
    }
  }

  /// Dismisses now — the reader swiped it away, or left the screen.
  public func dismiss() {
    dismissal?.cancel()
    dismissal = nil
    current = nil
  }
}
