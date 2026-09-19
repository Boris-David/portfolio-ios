import Decisions
import CoreUI
import Data
import DesignSystem
import Domain
import FeatureKit
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// Assembles the scene — and nothing else.
///
/// ## What it deliberately does not do
///
/// This file once held seven things: the tab bar, route resolution, sheet
/// resolution, the contact screen, the bar accessory, the launch-flag reading
/// and the environment wiring. "Root" had become a synonym for "wherever it did
/// not fit". Each is now a type that can be named, moved and tested on its own.
///
/// What is left is what a root is for: creating the long-lived objects, putting
/// them where the screens can find them, and connecting the few facts that
/// cross the whole app.
///
/// ## The one piece of logic that stayed, and why
///
/// A language change has to reach the content: the interface follows the reader's
/// choice instantly, but the text comes from the API and must be re-fetched.
/// `SettingsStore` will not call `PortfolioStore` — that would tie the two
/// together forever, for one line — so it **publishes a fact**, and this root
/// subscribes. It is the only place that sees both, which is precisely what a
/// composition root is.
public struct AppRoot: View {
  @State private var store: PortfolioStore
  @State private var resume: ResumeStore
  @State private var settings: SettingsStore
  @State private var toasts = ToastCenter()
  @State private var decision = DecisionController()
  @State private var selection: AppSection
  @State private var sheet: Sheet?
  @State private var cover: FullScreenCover?
  @Namespace private var zoom

  private let environment: AppEnvironment
  private let launch: LaunchArguments


  /// The app's entry point into the scene.
  ///
  /// Launch flags are deliberately **not** a parameter here: they are a
  /// screenshot-automation concern, not something the app target should know how
  /// to pass. The designated initialiser below takes them so the tests can.
  public init() {
    let launch = LaunchArguments.current
    // The base URL is read from the launch arguments before anything is built,
    // because it decides which endpoints the whole graph is wired to.
    let endpoints = launch.apiBaseURL.map(APIEndpoints.init(baseURL:)) ?? .production
    self.init(environment: .live(endpoints: endpoints), launch: launch)
  }

  public init(environment: AppEnvironment) {
    self.init(environment: environment, launch: .current)
  }

  init(environment: AppEnvironment, launch: LaunchArguments) {
    self.environment = environment
    self.launch = launch

    let settings = SettingsStore(
      preferences: environment.preferences,
      events: environment.events
    )
    _settings = State(initialValue: settings)
    _store = State(initialValue: PortfolioStore(
      reading: environment.portfolio,
      language: settings.resolvedLanguage,
    ))
    // Long-lived on purpose: it holds the downloaded document and its `ETag`,
    // so reopening the resume does not fetch it again. Built here rather than
    // inside the screen because the language it serves is decided here, and
    // nowhere else.
    _resume = State(initialValue: ResumeStore(
      reading: environment.resume,
      language: settings.resolvedLanguage
    ))
    _selection = State(initialValue: launch.initialSection)
  }

  public var body: some View {
    AppTabs(selection: $selection)
      .engineeringAccessory(isOn: decisionsBinding)
      .toasts(toasts)
      .modifier(sceneEnvironment)
      .sheet(item: $sheet) { sheet in
        // The same environment, applied again: a sheet is hosted outside the
        // presenting view's tree and inherits nothing from it.
        resolver(sheet)
          .modifier(sceneEnvironment)
      }
      // A document, not a detour. The résumé takes the whole screen: it wants
      // the width, and leaving it should be a decision rather than a stray
      // downward swipe.
      .fullScreenCover(item: $cover) { cover in
        FullScreenResolver.live(environment)(cover)
          .modifier(sceneEnvironment)
      }
      // `nil` means "follow the device", which is what `preferredColorScheme`
      // expects for that case — not a third scheme.
      .preferredColorScheme(settings.appearance.isDarkForced.map { $0 ? .dark : .light })
      .task {
        await settings.load()
        // Configured once, at launch, before any tip can be evaluated.
        DecisionsTipState.configure()
        // The launch flag wins over the stored preference **for this launch
        // only**, and does not write: a screenshot flag that changes what the
        // reader stored is a bug, and it was one.
        if launch.showsDecisions { settings.forceDecisions() }
        if launch.opensSettings { sheet = .settings }
        if launch.opensResume { cover = .resume }
        store.load()
      }
      .task { await followLanguageChanges() }
      .refreshingOnReturn(
        store: store,
        connectivity: environment.connectivity,
        events: environment.events
      )
      .onChange(of: settings.showsDecisions) { _, isOn in
        // The tip has done its job the moment the reader turns the mode on. The
        // rule is declarative, so nothing has to remember to invalidate it from
        // the right place.
        if isOn { DecisionsTipState.markUsed() }
        // A note left open after the mode is switched off would be a sheet with
        // no way back to what produced it.
        if !isOn { decision.dismiss() }
      }
  }

  private var resolver: SheetResolver { .live(environment) }

  private var sceneEnvironment: SceneEnvironment {
    SceneEnvironment(
      language: settings.resolvedLanguage,
      portfolio: store,
      resume: resume,
      settings: settings,
      toasts: toasts,
      decision: decision,
      sheets: resolver,
      openSettings: OpenSettingsAction { sheet = .settings },
      openResume: OpenResumeAction { cover = .resume },
      zoom: zoom,
      initialRoute: launch.initialRoute
    )
  }

  private var decisionsBinding: Binding<Bool> {
    Binding(
      get: { settings.showsDecisions },
      set: { value in Task { await settings.setShowsDecisions(value) } }
    )
  }

  /// Re-fetches the content when the language actually served changes.
  ///
  /// A `for await` over the bus rather than an `onChange` on the store: the fact
  /// is published once, by whoever knows it happened, and this is simply one
  /// subscriber. A second one — a widget, an analytics sink — costs nothing and
  /// requires no change here.
  private func followLanguageChanges() async {
    for await event in await environment.events.events {
      guard case .languageChanged(let language) = event else { continue }
      store.setLanguage(language)
      await resume.setLanguage(language)
    }
  }
}
