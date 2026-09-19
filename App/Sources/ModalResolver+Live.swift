import Domain
import FeatureContact
import FeatureKit
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
      case .resume:
        AnyView(ResumeScreen())
      }
    }
  }
}
