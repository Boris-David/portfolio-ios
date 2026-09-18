import Presentation
import SwiftUI

/// Who knows how to present a sheet.
public struct SheetResolver: Sendable {
  private let build: @MainActor @Sendable (Sheet) -> AnyView

  public init(build: @escaping @MainActor @Sendable (Sheet) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ sheet: Sheet) -> AnyView {
    build(sheet)
  }
}

public extension EnvironmentValues {
  @Entry var sheetResolver = SheetResolver { _ in AnyView(EmptyView()) }
}
