import Observation
import SwiftUI

/// The backstage mode's state, shared across the whole app.
///
/// `@Observable` rather than `ObservableObject`: SwiftUI then observes only the
/// properties each view **actually reads**. With `@Published`, turning the mode
/// on would have invalidated every view holding the object, including those that
/// only look at the selected note.
@Observable
@MainActor
public final class BackstageController {
  /// Are the annotations visible?
  public var isEnabled = false
  /// The note open in detail, if there is one.
  package var presented: BackstageNote?

  public init(isEnabled: Bool = false) {
    self.isEnabled = isEnabled
  }

  public func toggle() {
    isEnabled.toggle()
    if !isEnabled { presented = nil }
  }

  package func present(_ note: BackstageNote) {
    presented = note
  }
}

// The controller travels through `.environment(controller)` and is read with
// `@Environment(BackstageController.self)`.
//
// Not through an `@Entry` key: a key requires a **default value**, and building
// a main-actor-isolated object outside that actor does not compile. Working
// around it with `MainActor.assumeIsolated` would work — while planting a
// runtime trap in shipped code, for a defect nobody should ever hit.
//
// Object injection says better what is meant: this controller has no sensible
// default. Either the app provided it, or there is a wiring defect — and it is
// better to learn that on the first launch than to watch a backstage mode that
// responds to nothing.
