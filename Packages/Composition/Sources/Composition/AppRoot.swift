import Backstage
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// Assembles the scene — and nothing else.
///
/// ## What it deliberately no longer does
///
/// This file used to hold seven things: the tab bar, route resolution, sheet
/// resolution, the contact screen, the bar accessory, the launch-flag reading
/// and the environment wiring. "Root" had become a synonym for "wherever it
/// did not fit".
///
/// Each of those is now a type that can be named, moved and tested on its own:
/// `AppTabs`, `RouteResolver`, `SheetResolver`, `ContactScreen`,
/// `backstageAccessory`, `LaunchArguments`, `AppEnvironment`. What is left here
/// is the only thing a root is for: creating the long-lived objects and putting
/// them where the screens can find them.
public struct AppRoot: View {
  @State private var store: PortfolioStore
  @State private var backstage: BackstageController
  @State private var selection: AppSection

  private let environment: AppEnvironment

  /// The chrome is derived **here**, without going through the environment.
  ///
  /// `AppRoot` is the view that *installs* `\.contentLanguage`, and a view does
  /// not read back a value it sets itself — `.environment()` only applies to
  /// descendants. The defect was visible on screen: English content under
  /// French tabs.
  private var chrome: AppChrome { .for(environment.language) }

  /// The application's entry point into the scene.
  ///
  /// Launch flags are deliberately **not** a parameter here: they are a
  /// screenshot-automation concern, not something the app target should know
  /// how to pass. The designated initialiser below takes them so the tests can.
  public init(environment: AppEnvironment = .live()) {
    self.init(environment: environment, launch: .current)
  }

  init(environment: AppEnvironment, launch: LaunchArguments) {
    self.environment = environment
    let language = environment.language
    _store = State(initialValue: PortfolioStore(
      reading: environment.portfolio,
      language: language,
      // The store needs the chrome to turn a domain failure into something a
      // view can show. It takes a closure rather than a value so a language
      // change is reflected without rebuilding the store.
      chrome: { AppChrome.for(language) }
    ))
    _backstage = State(initialValue: BackstageController(isEnabled: launch.isBackstageEnabled))
    _selection = State(initialValue: launch.initialSection)
  }

  public var body: some View {
    AppTabs(selection: $selection)
      .backstageAccessory(controller: backstage, chrome: chrome)
      .environment(\.contentLanguage, environment.language)
      .environment(store)
      .environment(backstage)
      .environment(\.routeDestinations, .live)
      .environment(\.sheetDestinations, SheetResolver.live(
        resume: environment.resume,
        language: environment.language
      ))
      .tint(Color.accent)
      .task { store.load() }
  }
}
