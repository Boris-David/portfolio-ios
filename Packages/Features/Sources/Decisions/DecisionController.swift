import Observation
import Presentation

/// Which annotation is open, and nothing else.
///
/// ## What it deliberately stopped holding
///
/// It used to own `isEnabled` too. So did `SettingsStore`, because "show the
/// annotations" is a preference that survives a relaunch. Two booleans for one
/// fact — and they drifted the moment either could be set without the other:
/// toggling from the bar accessory left the settings screen showing the old
/// value, and the choice did not survive a relaunch.
///
/// The preference is now the single truth, in `SettingsStore`, and this holds
/// only what is genuinely transient: the note currently on screen, which nobody
/// would want restored three days later.
///
/// ## `@Observable` rather than `ObservableObject`
///
/// SwiftUI then observes only the properties each view **actually reads**. With
/// `@Published`, presenting a note would invalidate every view holding the
/// object, including those that never look at it.
@Observable
@MainActor
public final class DecisionController {
  /// The note open in detail, if there is one.
  package var presented: DesignDecision?

  public init() {}

  package func present(_ note: DesignDecision) {
    presented = note
  }

  /// Closes whatever is open. Called when the annotations are switched off, so
  /// a sheet does not survive the mode that produced it.
  public func dismiss() {
    presented = nil
  }
}

// The controller travels through `.environment(controller)` and is read with
// `@Environment(DecisionController.self)`.
//
// Not through an `@Entry` key: a key requires a **default value**, and building
// a main-actor-isolated object outside that actor does not compile. Working
// around it with `MainActor.assumeIsolated` would work — while planting a
// runtime trap in shipped code, for a defect nobody should ever hit.
//
// Object injection says better what is meant: this controller has no sensible
// default. Either the app provided it, or there is a wiring defect — and it is
// better to learn that on the first launch than to watch a decision mode that
// responds to nothing.
