public struct ProductionApp: Sendable, Hashable, Identifiable {
  /// The part he took in the app.
  public enum Role: String, Sendable, Hashable {
    /// His ticketing layer is embedded in it.
    case ticketing
    /// He shipped features into it, without owning a whole layer.
    case features
    /// He carried it end to end.
    case endToEnd = "end-to-end"
  }

  public var id: String { slug }

  /// The **public** slug — never an internal network identifier, which does not
  /// leave the building. It doubles as the icon's file name.
  public let slug: String
  public let name: String
  public let territory: String
  /// The store listing, when there is one.
  ///
  /// Nullable, and `sourceURL` is nullable for the opposite reason. An app
  /// shipped inside somebody else's product has a listing and no public source;
  /// an app of his own can be readable long before it is downloadable. The
  /// content guarantees at least one of the two — a card with no destination
  /// would lie about being tappable.
  public let appStoreURL: URLString?
  /// The public repository, when the code is open.
  public let sourceURL: URLString?
  /// One sentence on what the app is — `nil` where a case study already says it.
  public let summary: String?
  public let role: Role

  public init(
    slug: String,
    name: String,
    territory: String,
    appStoreURL: URLString?,
    sourceURL: URLString?,
    summary: String?,
    role: Role
  ) {
    self.slug = slug
    self.name = name
    self.territory = territory
    self.appStoreURL = appStoreURL
    self.sourceURL = sourceURL
    self.summary = summary
    self.role = role
  }
}
