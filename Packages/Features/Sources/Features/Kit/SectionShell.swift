import Backstage
import DesignSystem
import Presentation
import SwiftUI
import ViewKit

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

  @Environment(\.routeResolver) private var routes
  @Environment(\.sheetResolver) private var sheets
  @Environment(\.openSettings) private var openSettings
  @Environment(\.openResume) private var openResume
  @Chrome private var chrome
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
        // The gear sits on every tab root rather than on one screen: settings
        // belong to the app, and a reader who wants them should not have to
        // remember which section hides them.
        // Two permanent items, on every tab root.
        //
        // The résumé first: *"getting to the CV download has to be easier and
        // more obvious."* It was a button halfway down the home screen, behind a
        // scroll. A toolbar item is reachable from wherever the reader is, in
        // one tap, and it is the same tap every time — which is what makes it
        // findable rather than merely present.
        //
        // Settings second, because it is the one people look for last.
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button { openResume() } label: {
              Label(chrome.resumeAction, icon: .resume)
            }
            .accessibilityLabel(chrome.resumeAction)
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button { openSettings() } label: {
              Label(chrome.settings, icon: .settings)
            }
            .accessibilityLabel(chrome.settings)
          }
        }
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
