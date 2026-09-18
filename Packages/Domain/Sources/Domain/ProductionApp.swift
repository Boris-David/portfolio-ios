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
  public let appStoreURL: URLString
  public let role: Role

  public init(slug: String, name: String, territory: String, appStoreURL: URLString, role: Role) {
    self.slug = slug
    self.name = name
    self.territory = territory
    self.appStoreURL = appStoreURL
    self.role = role
  }
}
