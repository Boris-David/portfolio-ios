import Domain
import FeatureContact
import FeatureKit
import FeatureResume
import Presentation
import SwiftUI

/// Turns a sheet into a screen.
///
/// Same reasoning as `RouteResolver`, and the same reason it lives here: a
/// screen presents `Sheet.resume` without knowing that `FeatureResume` exists.
enum SheetResolver {
  /// The resolution the application installs into the environment.
  @MainActor
  static func live(resume: any ResumeReading, language: Language) -> SheetDestinations {
    SheetDestinations { sheet in
      switch sheet {
      case .resume:
        AnyView(ResumeScreen(reading: resume, language: language))
      case .contact:
        AnyView(ContactScreen())
      }
    }
  }
}
