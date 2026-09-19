import SwiftUI

/// What a deep link to content that is not there shows.
///
/// It happens: a link arrives before the first load finishes, or names a case
/// study the source no longer serves. Saying so beats a blank screen, and saying
/// it in one place beats four resolvers each inventing their own wording.
public struct RouteMissingView: View {
  public init() {}

  @Localized(.interface) private var text

  public var body: some View {
    ContentUnavailableView {
      // The glyph name never leaves this module: the caller asks for a
      // *meaning* and the view layer draws it.
      Label(text(InterfaceText.routeMissingTitle), icon: .empty)
    } description: {
      Text(text(InterfaceText.routeMissingMessage))
    }
  }
}
