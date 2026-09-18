import Backstage
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
struct SceneEnvironment: ViewModifier {
  let language: Language
  let portfolio: PortfolioStore
  let settings: SettingsStore
  let toasts: ToastCenter
  let backstage: BackstageController
  let sheets: SheetResolver
  let openSettings: OpenSettingsAction
  let openResume: OpenResumeAction

  func body(content: Content) -> some View {
    content
      .environment(\.contentLanguage, language)
      .environment(portfolio)
      .environment(settings)
      .environment(toasts)
      .environment(backstage)
      .environment(\.routeResolver, .live)
      .environment(\.sheetResolver, sheets)
      .environment(\.openSettings, openSettings)
      .environment(\.openResume, openResume)
      .tint(Color.accent)
  }
}
