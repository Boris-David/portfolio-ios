import SwiftUI

/// Opens the settings sheet, from wherever the reader is.
///
/// ## Why an environment action and not a route
///
/// Settings is not a destination inside a tab's stack: it is a modal task that
/// belongs to the app, not to the section you happen to be reading. Pushing it
/// onto a stack would leave it behind a back button that says "Profile", and
/// switching tabs would lose it.
///
/// An action in the environment also keeps `SectionShell` — which draws the
/// toolbar button — from knowing that a settings screen exists at all. It calls
/// a closure; the composition root decides what that closure does.
public struct OpenSettingsAction: Sendable {
  private let open: @MainActor @Sendable () -> Void

  public init(_ open: @escaping @MainActor @Sendable () -> Void) {
    self.open = open
  }

  @MainActor
  public func callAsFunction() { open() }
}

public extension EnvironmentValues {
  /// Does nothing by default. An app that forgot to wire it would show a gear
  /// that responds to nothing — visible on the first tap, which is the point of
  /// not crashing instead.
  @Entry var openSettings = OpenSettingsAction {}
}
