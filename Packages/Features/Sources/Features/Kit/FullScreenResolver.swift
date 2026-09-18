import Presentation
import SwiftUI

/// Who knows how to present a full-screen cover.
///
/// Same shape and same reason as `RouteResolver` and `SheetResolver`: a screen
/// declares a **value**, and the composition root — the only module that sees
/// every feature — turns it into a view.
public struct FullScreenResolver: Sendable {
  private let build: @MainActor @Sendable (FullScreenCover) -> AnyView

  public init(build: @escaping @MainActor @Sendable (FullScreenCover) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ cover: FullScreenCover) -> AnyView {
    build(cover)
  }
}

public extension EnvironmentValues {
  @Entry var fullScreenResolver = FullScreenResolver { _ in AnyView(EmptyView()) }
}

/// Opens the résumé, from wherever the reader is.
///
/// ## Why an action rather than a route
///
/// The résumé is not a place inside a section's stack — it is a document. Pushed,
/// it would sit behind a back button labelled with whichever tab the reader
/// happened to be on, and switching tabs would lose it.
public struct OpenResumeAction: Sendable {
  private let open: @MainActor @Sendable () -> Void

  public init(_ open: @escaping @MainActor @Sendable () -> Void) {
    self.open = open
  }

  @MainActor
  public func callAsFunction() { open() }
}

public extension EnvironmentValues {
  @Entry var openResume = OpenResumeAction {}
}
