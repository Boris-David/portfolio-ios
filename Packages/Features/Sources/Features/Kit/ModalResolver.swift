import Presentation
import SwiftUI

/// Who knows how to build a modal's screen.
///
/// Same shape and same reason as `RouteResolver`: a screen declares a **value**,
/// and the composition root — the only module that sees every feature — turns it
/// into a view. `ProfileBlocks` asks for `.contact` without knowing that
/// `FeatureContact` exists, and `SectionShell` draws a gear without knowing that
/// a settings screen was ever written.
public struct ModalResolver: Sendable {
  private let build: @MainActor @Sendable (Modal) -> AnyView

  public init(build: @escaping @MainActor @Sendable (Modal) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ modal: Modal) -> AnyView {
    build(modal)
  }
}

/// Presents a modal, from wherever the reader is.
///
/// ## Why an action and not a route
///
/// None of the three is a place inside a section's stack. Pushed, the résumé
/// would sit behind a back button labelled with whichever tab the reader
/// happened to be on, and switching tabs would lose it. They belong to the
/// application, so the application presents them.
///
/// ## Why one action and not three
///
/// `openSettings` and `openResume` were two identical closures with two names,
/// and `.contact` went through a third mechanism entirely — a property on the
/// section's router. Three ways to say one thing is three places to get it
/// wrong, and one of them already was: the router's sheet was presented from an
/// anchor that did not re-apply the scene's environment.
///
/// One action, one anchor. `present(.settings)` reads as well as
/// `openSettings()` did, and it is the only way there is.
public struct PresentAction: Sendable {
  private let show: @MainActor @Sendable (Modal) -> Void

  public init(_ show: @escaping @MainActor @Sendable (Modal) -> Void) {
    self.show = show
  }

  @MainActor
  public func callAsFunction(_ modal: Modal) { show(modal) }
}

public extension EnvironmentValues {
  /// Nothing by default — an app that forgot to wire the resolution would show
  /// empty modals, which is obvious on the very first try.
  @Entry var modalResolver = ModalResolver { _ in AnyView(EmptyView()) }

  /// Does nothing by default. An app that forgot to wire it would show a gear
  /// that responds to nothing — visible on the first tap, which is the point of
  /// not crashing instead.
  @Entry var present = PresentAction { _ in }
}
