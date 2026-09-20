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
  @ReducedMotion private var reducedMotion
  @State private var reselection = SectionReselection()
  /// Whether the welcome screen has handed over. See `WelcomeScreen`.
  @State private var hasOpened = false
  @State private var selection: AppSection
  @State private var modal: Modal?

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
    ZStack {
      tabs
      if !hasOpened {
        WelcomeScreen(profile: store.portfolio?.profile)
          .transition(.opacity)
          .zIndex(1)
      }
    }
    .animation(reducedMotion ? nil : Motion.entrance, value: hasOpened)
    .task { await openWhenReady() }
  }

  /// Hands over to the app once the content is there — and never before the
  /// floor, so the welcome cannot flash and be gone.
  ///
  /// It waits for **either** outcome of the first load, not for success: an
  /// offline launch shows the failure screen, which is content of a kind, and
  /// sitting on a greeting for ever would be worse than saying what happened.
  private func openWhenReady() async {
    let floor = Task {
      try? await Task.sleep(for: .seconds(Tokens.Duration.welcome))
    }
    while store.phase.isPending {
      await Task.yield()
      try? await Task.sleep(for: .milliseconds(50))
    }
    await floor.value
    hasOpened = true
  }

  /// The application itself, under the welcome screen.
  private var tabs: some View {
    AppTabs(selection: tabSelection)
      .resumeAccessory(present: presentAction, isOpen: modal == .resume)
      .toasts(toasts)
      // ⚠️ **Inside** `sceneEnvironment`, and the order is the whole of it.
      //
      // A sheet inherits the environment as it stands at the point the `.sheet`
      // modifier is attached — not the environment of whatever ends up on
      // screen. Attached after `.sceneEnvironment(scene)` this sits *outside*
      // it, and the modifier itself cannot even read the controller: *No
      // Observable object of type DecisionController found*, on the first tap.
      //
      // The two modal anchors below are the opposite case: they are attached
      // outside on purpose and re-apply the environment inside their content,
      // because a sheet presented from the scene is hosted outside the scene's
      // tree. This one is attached inside and needs no re-application.
      .decisionSheet(isEnabled: modal == nil)
      .sceneEnvironment(scene)
      // The **one** place the app presents anything over the scene. Which
      // presentation a modal gets is the modal's own answer, not the caller's
      // — see `Modal.style`.
      //
      // The environment is applied again inside, because a presented screen is
      // hosted outside the presenting view's tree and inherits nothing from it.
      .sheet(item: modalBinding(.sheet)) { modal in
        resolver(modal).sceneEnvironment(scene)
      }
      .fullScreenCover(item: modalBinding(.fullScreen)) { modal in
        resolver(modal).sceneEnvironment(scene)
      }
      // The decision note, presented from the scene — and only while the scene
      // is what the reader is looking at. A screen presented over it brings its
      // own anchor; see `decisionSheet(isEnabled:)`.
      // `nil` means "follow the device", which is what `preferredColorScheme`
      // expects for that case — not a third scheme.
      .preferredColorScheme(settings.appearance.isDarkForced.map { $0 ? .dark : .light })
      .task {
        // ⚠️ The fetch starts **before** the stored preferences are read.
        //
        // It used to wait for them, and the wait was on the critical path of
        // every cold start for a value that almost never changes anything: the
        // store is built with the language the device resolves to, and the
        // stored preference agrees with it unless the reader chose otherwise.
        //
        // `setLanguage` below is a no-op when they agree, and a re-fetch when
        // they do not — which is the rare case paying for itself instead of
        // every launch paying for it.
        store.load()
        await settings.load()
        await serve(settings.resolvedLanguage)
        // Configured once, at launch, before any tip can be evaluated.
        DecisionsTipState.configure()
        // The launch flag wins over the stored preference **for this launch
        // only**, and does not write: a screenshot flag that changes what the
        // reader stored is a bug, and it was one.
        if launch.showsDecisions { settings.forceDecisions() }
        if let initialModal = launch.initialModal { modal = initialModal }
      }
      // A link from the website. The one place the app changes tab without the
      // reader touching the bar — and it is the reader who touched the link,
      // which is the exception the rule is written for.
      .onOpenURL { url in
        guard let link = DeepLink(url) else { return }
        selection = link.section
        if let requested = link.modal { modal = requested }
      }
      .task { await prefetchResume() }
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

  private var resolver: ModalResolver { .live(environment) }

  private var presentAction: PresentAction {
    PresentAction { modal = $0 }
  }

  /// Everything the scene owns, gathered once and applied wherever a root is
  /// needed — see `SceneEnvironment`.
  private var scene: SceneEnvironment {
    SceneEnvironment(
      language: settings.resolvedLanguage,
      portfolio: store,
      resume: resume,
      settings: settings,
      toasts: toasts,
      decision: decision,
      reselection: reselection,
      present: presentAction,
      modals: resolver,
      initialRoute: launch.initialRoute
    )
  }

  /// The half of `modal` a given presentation is responsible for.
  ///
  /// One piece of state, two anchors: whichever anchor the current modal does
  /// not belong to sees `nil` and stays closed. Dismissing only clears the
  /// state when it is that anchor's modal — without the guard, the cover's
  /// binding would clear a sheet the moment it appeared.
  private func modalBinding(_ style: Modal.Style) -> Binding<Modal?> {
    Binding(
      get: { modal?.style == style ? modal : nil },
      set: { value in
        guard value == nil, modal?.style == style else { return }
        modal = nil
      }
    )
  }

  /// The tab bar's selection, with the one gesture `TabView` does not report.
  ///
  /// A binding is only written when the value **changes**, so tapping the tab
  /// you are already on writes nothing — SwiftUI does call the setter, with the
  /// same value. That equal write is the gesture, and this is the only place in
  /// the app that can see it.
  private var tabSelection: Binding<AppSection> {
    Binding(
      get: { selection },
      set: { section in
        if section == selection {
          reselection.record(section)
        } else {
          selection = section
        }
      }
    )
  }

  /// Fetches the résumé once the portfolio is on screen.
  ///
  /// ## Why the app spends a request nobody asked for
  ///
  /// Because the résumé is what this application exists to deliver, and the
  /// reader reaches it from a control that follows them through every screen.
  /// Fetched on demand, the cover opened on a spinner; fetched in the quiet
  /// after the first screen has drawn, it opens on the document.
  ///
  /// It waits for the portfolio deliberately: two requests racing on a cold
  /// start would make the screen the reader is actually looking at slower, to
  /// speed up one they may never open.
  private func prefetchResume() async {
    while store.phase.isPending {
      await Task.yield()
      try? await Task.sleep(for: .milliseconds(50))
    }
    guard !resume.phase.isLoaded else { return }
    await resume.load()
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
      await serve(language)
    }
  }

  /// Puts one language in front of the reader — in **every** store that has
  /// one.
  ///
  /// ## The bug this exists to make unwriteable
  ///
  /// There were two call sites and they had drifted. The one that runs at
  /// launch set the language on the portfolio and not on the résumé, so a
  /// reader whose device is English and whose stored choice is French got a
  /// French app and an **English CV** — the one document the app exists to
  /// deliver, in the wrong language, with nothing on screen to explain it.
  ///
  /// Both stores are built in `init` with whatever the device resolves to,
  /// because the stored preference has not been read yet. Correcting one of
  /// them afterwards and not the other is a line anybody can forget, and
  /// somebody did.
  ///
  /// One function, called from the two places a language can change: the first
  /// read of the preferences, and the event the settings screen publishes.
  /// Adding a third store means adding it here, where the other two are.
  private func serve(_ language: Language) async {
    store.setLanguage(language)
    await resume.setLanguage(language)
  }
}
