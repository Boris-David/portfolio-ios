/// The destinations reachable from a tab.
///
/// A `Hashable` enum and **value-based** navigation: the view declares
/// `NavigationLink(value:)`, and the root resolves it. A
/// `NavigationLink(destination:)` would couple each row to the screen it opens
/// — the row could never be reused elsewhere, and that screen could never be
/// opened from a deep link.
/// ⚠️ **Every case must render something.** `RouteScreen` switches without a
/// `default:`, so adding a case here does not compile until a screen exists for
/// it. That is not ceremony: `experience` and `allApps` sat in this enum for
/// weeks, resolved by a `default: EmptyView()`, and `expertise` — which the
/// profile screen pushes on a tap — opened a **black screen** in production.
public enum Route: Hashable, Sendable {
  case caseStudy(slug: String)
  case expertise(id: String)
  /// The long-form introduction, which the first screen deliberately does not
  /// carry: an opening gives the scale, not the story.
  case about
  /// How **this** application is built: its layers, the problems it ran into,
  /// the dependencies it took and refused.
  ///
  /// It was a tab. A tab is somewhere you return to, and nobody returns to a
  /// list of architecture decisions — they read it once, because a project made
  /// them curious. So it is pushed from the work tab, where the curiosity comes
  /// from, and the bar got its fourth *destination* back.
  case engineering
  /// The comparison of architecture patterns, and the codebases read against
  /// them. A reading, pushed from the engineering one.
  case architectures
}
