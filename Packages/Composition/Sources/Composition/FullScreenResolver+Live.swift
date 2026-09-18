import FeatureKit
import FeatureResume
import Presentation
import SwiftUI

extension FullScreenResolver {
  /// The resolution the application installs.
  @MainActor
  static func live(_ environment: AppEnvironment) -> FullScreenResolver {
    FullScreenResolver { cover in
      switch cover {
      case .resume:
        AnyView(ResumeScreen())
      }
    }
  }
}
