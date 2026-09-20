import Domain
import FeatureContact
import FeatureKit
import FeatureProfile
import FeatureResume
import FeatureSettings
import Presentation
import SwiftUI

/// Turns a modal into a screen.
///
/// Same reasoning as `RouteResolver`, and the same reason it lives here: a
/// screen asks for `Modal.contact` without knowing that `FeatureContact` exists.
///
/// ## Why it takes the whole environment
///
/// Because it is *in* the composition root, and this is the one place allowed to
/// see everything. What it hands each screen, though, is only that screen's
/// slice — `ResumeScreen` gets a `ResumeDependencies`, not an `AppEnvironment`.
/// The breadth stops here.
extension ModalResolver {
  @MainActor
  static func live(_ environment: AppEnvironment) -> ModalResolver {
    ModalResolver { modal in
      switch modal {
      case .contact:
        AnyView(ContactScreen())
      case .settings:
        AnyView(SettingsScreen())
      case .personality:
        AnyView(PersonalityScreen())
      case .resume:
        AnyView(ResumeScreen())
      case .reading(let route):
        // The same screen the stack would have pushed, resolved by the same
        // resolver — in a stack of its own so it keeps a title, and with one
        // way out instead of a trail of back buttons.
        AnyView(PresentedReadingScreen(route: route))
      }
    }
  }
}
