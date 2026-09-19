import Testing
@testable import Presentation

/// Announcing something, and stopping announcing it.
///
/// ## Why any of this is testable at all
///
/// A toast is usually written as a view with a timer inside it, and then the
/// only way to find out what happens when a second one arrives during the first
/// is to tap fast on a simulator. Here the decisions — what is shown, what
/// replaces what, when it stops being relevant — are values, so the awkward
/// cases are assertions.
///
/// The duration is injected for the same reason: a suite that proves a toast
/// leaves after three seconds by waiting three seconds is a suite people start
/// skipping.
@MainActor
struct ToastCenterTests {
  /// Long enough that nothing expires while a test is looking at it.
  private static let calm = Duration.seconds(30)

  @Test("a second toast replaces the first rather than queueing behind it")
  func showReplaces() {
    let center = ToastCenter(duration: Self.calm)

    center.show("Copied", kind: .succeeded, icon: .succeeded)
    center.show("Link opened", kind: .informed, icon: .link)

    // Queueing would mean showing the reader a message about something that
    // happened several seconds and one screen ago. The most recent fact is the
    // only one still worth the space.
    #expect(center.current?.message == "Link opened")
    #expect(center.current?.kind == .informed)
    #expect(center.current?.icon == .link)
  }

  /// ⚠️ **The subtle one.**
  ///
  /// Copy something, then copy it again: two events, the same words. If the
  /// message were the identity, SwiftUI would consider the second toast the
  /// same view as the first, keep it in place, and restart neither the
  /// animation nor the timer — so the second tap would look like it did
  /// nothing at all, on the one gesture whose only feedback is this toast.
  ///
  /// Nothing about the state would look wrong while that happened, which is why
  /// the identity is asserted directly rather than inferred from behaviour.
  @Test("two identical messages in a row are two distinct toasts")
  func identicalMessagesGetDistinctIdentities() throws {
    let center = ToastCenter(duration: Self.calm)

    center.show("Copied", kind: .succeeded, icon: .succeeded)
    let first = try #require(center.current)
    center.show("Copied", kind: .succeeded, icon: .succeeded)
    let second = try #require(center.current)

    #expect(first.message == second.message)
    #expect(first.id != second.id, "identical messages must not share an identity")
    #expect(first != second)
  }

  @Test("dismissing takes the toast away at once, without waiting for its time")
  func dismissIsImmediate() {
    let center = ToastCenter(duration: Self.calm)

    center.show("Copied", kind: .succeeded, icon: .succeeded)
    center.dismiss()

    #expect(center.current == nil)
  }

  /// ⚠️ The defect this catches: `dismiss` clears the toast and lets go of the
  /// pending timer **without cancelling it**. Everything looks right — the
  /// toast does leave — until the orphaned timer comes due and wipes whatever
  /// is on screen by then. Nothing holds a reference to it any more, so nothing
  /// can stop it.
  ///
  /// The timeline, with a life of 600 ms: the first toast is shown at 0 and
  /// dismissed at 500, so an orphan would be due at 600. The second is shown at
  /// 500 and is due at 1100. The assertion at 700 sits between the two, and
  /// only the orphan can empty the screen there.
  @Test("dismissing disarms the pending timer, so the next toast lives its own life")
  func dismissCancelsThePendingTimer() async throws {
    let center = ToastCenter(duration: .milliseconds(600))
    center.show("Copied", kind: .succeeded, icon: .succeeded)

    try await Task.sleep(for: .milliseconds(500))
    center.dismiss()
    center.show("Résumé downloaded", kind: .succeeded, icon: .resume)

    try await Task.sleep(for: .milliseconds(200))
    #expect(
      center.current?.message == "Résumé downloaded",
      "a timer left armed by the previous toast cut this one short"
    )
  }

  /// A toast that never leaves is a banner, and it stops being a toast the
  /// moment the reader has to deal with it.
  @Test("a toast leaves on its own once its time is up")
  func autoDismissesWhenItsTimeIsUp() async throws {
    let center = ToastCenter(duration: .milliseconds(50))

    center.show("Copied", kind: .succeeded, icon: .succeeded)
    #expect(center.current != nil)

    // Polled rather than slept through: the claim is "it goes away", not "it
    // goes away in exactly 50 ms". A single sleep of the exact duration tests
    // the scheduler's punctuality, and fails on a busy machine for a reason
    // that has nothing to do with this code.
    #expect(try await waitUntilTrue { center.current == nil }, "the toast never left")
  }

  /// Polls a condition on the main actor until it holds, or until the deadline.
  /// Returns whether it held, so the caller can say what it was waiting for.
  private func waitUntilTrue(
    within limit: Duration = .seconds(2),
    _ condition: () -> Bool
  ) async throws -> Bool {
    let step = Duration.milliseconds(10)
    for _ in 0..<Int(limit / step) {
      if condition() { return true }
      try await Task.sleep(for: step)
    }
    return condition()
  }
}
