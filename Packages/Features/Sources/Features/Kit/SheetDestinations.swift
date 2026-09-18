import Presentation
import SwiftUI

/// Who knows how to present a sheet.
public struct SheetDestinations: Sendable {
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
  @Entry var sheetDestinations = SheetDestinations { _ in AnyView(EmptyView()) }
}
