import Observation

/// One section's router.
///
/// One per tab, never a global one: sharing a stack between tabs sends the user
/// back to another tab's screen when they tap "back", which means nothing to
/// them.
///
/// It lives in `Presentation` and not in a view module because *where a tap
/// leads* is a decision, not a rendering. Which is also what makes it testable:
/// pushing twice and popping once is an assertion on an array, with no renderer
/// involved.
///
/// ## What it deliberately no longer holds
///
/// A `sheet` property, and a `present(_:)` to set it. A modal is not a place
/// inside a section — it belongs to the application — and holding one here gave
/// the app a **second** presentation anchor, which is how the scene environment
/// came to be missing on one of them. Modals go through `Modal` and the one
/// anchor the scene owns.
@Observable
@MainActor
public final class Router {
  /// How deep a section's stack goes before a reading is presented instead.
  ///
  /// **One.** A single push is a detour: one back button, and it is the tab you
  /// started on. From the second, the reader is counting back taps — which is
  /// exactly what they reported, on the very first case where it happens:
  /// profile → a deep dive → the case study it cites, and two backs to get
  /// home.
  ///
  /// ⚠️ It was two, on the reading that "beyond two successive pushes" meant
  /// the third. It does not: the second push is already the one that costs two
  /// backs, so the rule as written allowed precisely the thing it was added to
  /// prevent. The number is the reader's patience, and the reader said one.
  public static let readableDepth = 1

  public var path: [Route] = []

  public init() {}

  public func push(_ route: Route) { path.append(route) }
  public func pop() { if !path.isEmpty { path.removeLast() } }
  public func popToRoot() { path.removeAll() }
}
