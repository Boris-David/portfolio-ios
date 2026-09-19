import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI

/// Everything the scene puts where the screens can find it — declared **once**.
///
/// ## The defect this exists to prevent
///
/// A sheet's content does not inherit the environment of the view that presents
/// it. That sounds like a detail and it is a crash: opening the settings sheet
/// brought down the app with *"No Observable object of type SettingsStore
/// found"*, because the `.environment(settings)` sat on the tab view and the
/// sheet is hosted somewhere else entirely.
///
/// The obvious fix — repeat the eight `.environment` calls inside the sheet — is
/// the one that eventually goes wrong: two lists that must agree are two lists
/// that will not, and the day they diverge the failure is again a crash on one
/// screen. So the list is a single modifier, applied wherever a root is needed.
///
/// It was found by launching the app with `-settings` and looking. Nothing in
/// the build said a word.
///
/// ## And the second half of the same defect
///
/// Applying it correctly on every anchor only works if you can count the
/// anchors. There were two — this one and a `.sheet` on every section's stack —
/// and the second never applied it. It had simply never been reached, because
/// nothing but the contact card used it.
///
/// There is now one `Modal` type and one anchor. The list below is applied
/// twice in `AppRoot`, on lines you can see without scrolling.
///
/// ## Why it is applied through a named modifier
///
/// `.modifier(sceneEnvironment)` says *that* a modifier is applied and never
/// *which*: the reader has to go and look. `.sceneEnvironment(scene)` says it
/// at the call site, the way every other modifier in this codebase does —
/// `.decisionSheet()`, `.returningToTop()`, `.navigationDetail(_:)`.
///
/// `check-layers.sh` refuses a bare `.modifier(` in a view from now on.
struct SceneEnvironment: ViewModifier {
  let language: Language
  let portfolio: PortfolioStore
  let resume: ResumeStore
  let settings: SettingsStore
  let toasts: ToastCenter
  let decision: DecisionController
  let reselection: SectionReselection
  let present: PresentAction
  let modals: ModalResolver
  let initialRoute: Route?

  func body(content: Content) -> some View {
    content
      .environment(\.contentLanguage, language)
      .environment(portfolio)
      .environment(resume)
      .environment(settings)
      .environment(toasts)
      .environment(decision)
      .environment(reselection)
      .environment(\.routeResolver, .live)
      .environment(\.modalResolver, modals)
      .environment(\.present, present)
      .environment(\.initialRoute, initialRoute)
      .tint(Color.accent)
  }
}

extension View {
  /// Puts everything the scene owns where the screens can find it.
  func sceneEnvironment(_ scene: SceneEnvironment) -> some View {
    modifier(scene)
  }
}
