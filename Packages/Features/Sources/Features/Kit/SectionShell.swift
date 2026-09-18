import Backstage
import DesignSystem
import Presentation
import SwiftUI

/// The shell every tab is mounted in: a stack, its destinations, its sheets,
/// and the annotation layer.
///
/// Written once rather than copied into the four tabs. That is not only an
/// economy: `.navigationDestination(for:)` must be declared **once per stack and
/// per type**, and declaring it twice produces behaviour SwiftUI does not define
/// — it picks, without warning.
package struct SectionShell<Content: View>: View {
  private let title: String
  private let content: Content

  @Environment(\.routeDestinations) private var routes
  @Environment(\.sheetDestinations) private var sheets
  @State private var router = Router()

  public init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  public var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      content
        .background(Color.paper)
        .navigationTitle(title)
        // `.inline` everywhere, root included: a large title that shrinks on
        // scroll moves the layout while you are reading, and the app already has
        // its own section headers.
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
          routes(route)
            // The tab bar hides on pushed screens: they are a reading, not a
            // destination you navigate between.
            .toolbar(.hidden, for: .tabBar)
        }
    }
    .sheet(item: $router.sheet) { sheets($0) }
    .environment(router)
    .backstageOverlay()
  }
}
