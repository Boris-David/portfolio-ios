/// The app's tabs.
///
/// ## Why the fourth one is a product and not "engineering"
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
/// thing this app was not showing: an application he took end to end, published
/// on the App Store, whose four screenshots were already in the bundle and
/// rendered by nobody.
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
