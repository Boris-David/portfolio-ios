import DesignSystem
import SwiftUI

/// The entry point.
///
/// ## Why the wiring sits in this target and not in a package
///
/// It used to be a package, `Composition`, on the argument that its tests could
/// then run **without a simulator**. That argument was checked on 2026-09-18 and
/// did not survive: every package here declares `.iOS(.v18)` only, so `swift
/// test` does not compile at all, and `Scripts/test.sh` has always run every
/// suite on a simulator. The benefit was never collected.
///
/// What it cost was the shape. In clean architecture the composition root is the
/// outermost ring — the one thing **nobody imports**. `AmissanApp` wrote
/// `import Composition`, which made the root a library wearing a root's name.
/// Three times during the string-catalogue migration that package tried to
/// resolve a label and the compiler refused it, because `package` visibility
/// stops at a package boundary. Each refusal was right, and each one was the
/// graph saying the root was in the wrong place.
///
/// ⚠️ What this target gave up, and what replaced it: the app used to see only
/// `Composition`, so it could not write `import Networking`. It now declares the
/// whole graph, because assembling is its job. `Scripts/check-layers.sh` refuses
/// a screen here instead — no catalogue, no key, no content. The boundary that
/// matters, a **screen** that cannot reach the network, is held where it always
/// was: `Features/Package.swift`.
@main
struct AmissanApp: App {
  /// The one thing that has to happen before the first frame.
  ///
  /// The navigation bar's large title is dressed through UIKit's appearance
  /// proxy, which applies to bars created **after** it is set. Installed in the
  /// initialiser rather than in a `.task`, which runs once the first bar
  /// already exists — and would have shown the system face for one frame.
  init() {
    NavigationAppearance.install()
  }

  var body: some Scene {
    WindowGroup {
      AppRoot()
    }
  }
}
