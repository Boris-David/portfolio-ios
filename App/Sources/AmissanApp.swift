import Composition
import SwiftUI

/// The entry point.
///
/// Deliberately tiny: twelve lines. Everything that could live here — building
/// the dependencies, choosing the language, composing the screens — lives in
/// `Composition`, which is a module that **builds and tests without a
/// simulator**.
///
/// A `@main` that grows is a `@main` that cannot be tested: nothing it contains
/// is reachable except by launching the app.
@main
struct AmissanApp: App {
  var body: some Scene {
    WindowGroup {
      AppRoot()
    }
  }
}
