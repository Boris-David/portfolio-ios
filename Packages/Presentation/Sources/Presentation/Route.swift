/// The destinations reachable from a tab.
///
/// A `Hashable` enum and **value-based** navigation: the view declares
/// `NavigationLink(value:)`, and the root resolves it. A
/// `NavigationLink(destination:)` would couple each row to the screen it opens
/// — the row could never be reused elsewhere, and that screen could never be
/// opened from a deep link.
public enum Route: Hashable, Sendable {
  case caseStudy(slug: String)
  case experience(slug: String)
  case expertise(id: String)
  case allApps
}
