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
@Observable
@MainActor
public final class Router {
  public var path: [Route] = []
  public var sheet: Sheet?

  public init() {}

  public func push(_ route: Route) { path.append(route) }
  public func pop() { if !path.isEmpty { path.removeLast() } }
  public func popToRoot() { path.removeAll() }
  public func present(_ sheet: Sheet) { self.sheet = sheet }
}
