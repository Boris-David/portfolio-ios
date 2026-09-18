/// Les applications en production qui embarquent son travail.
public struct AppCatalogue: Sendable, Hashable {
  /// La date à laquelle les identifiants App Store ont été revérifiés. Publiée
  /// telle quelle : un chiffre vérifiable vaut par la date de sa vérification.
  public let verifiedOn: String
  public let items: [ProductionApp]

  public init(verifiedOn: String, items: [ProductionApp]) {
    self.verifiedOn = verifiedOn
    self.items = items
  }

  /// Celles dont il porte la couche de billettique.
  public var ticketing: [ProductionApp] {
    items.filter { $0.role == .ticketing }
  }
}

public struct ProductionApp: Sendable, Hashable, Identifiable {
  /// La part qu'il a prise dans l'application.
  public enum Role: String, Sendable, Hashable {
    /// Sa couche de billettique y est embarquée.
    case ticketing
    /// Il y a livré des fonctionnalités, sans en porter une couche entière.
    case features
    /// Il l'a tenue de bout en bout.
    case endToEnd = "end-to-end"
  }

  public var id: String { slug }

  /// Le slug **public** — jamais un identifiant de réseau interne, qui ne sort
  /// pas. Il sert aussi de nom de fichier d'icône.
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
