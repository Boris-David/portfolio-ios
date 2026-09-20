/// The app's tabs.
///
/// ## Why the fourth one is his own work and not "engineering"
///
/// It held the engineering record — layers, challenges, dependency
/// arbitrations — on the reasoning that a portfolio showing screens shows a
/// result, and this tab shows the decisions. The reasoning still holds; the
/// **placement** did not.
///
/// A tab is a destination somebody returns to. Nobody returns to a list of
/// architecture decisions; they read it once, if at all, and they read it
/// because a project made them curious. So it became a reading pushed from the
/// work tab, where the curiosity comes from — and the slot went to the one
/// thing this app was not showing: what he built himself, end to end.
///
/// ## What "his own" draws the line on
///
/// Not the thirty-three transport apps, which carry his ticketing layer inside
/// somebody else's product — those belong to the problems tab, where the case
/// study explains what he did in them. Here: the apps that are his from the
/// first line, including **this one**, whose repositories are public and whose
/// store listing does not exist yet.
///
/// That is also why the tab is named after possession rather than after apps.
/// "Apps" would collide with the grid of thirty-three one tab to the left;
/// "my apps" is the distinction the reader needs, and it is the distinction the
/// author drew himself.
public enum AppSection: String, CaseIterable, Hashable, Sendable, Identifiable {
  case profile
  case work
  case journey
  case product

  public var id: String { rawValue }

  /// A meaning, which `ViewKit` turns into a glyph. See `Icon`.
  public var icon: Icon {
    switch self {
    case .profile: .profile
    case .work: .work
    case .journey: .journey
    case .product: .product
    }
  }
}
