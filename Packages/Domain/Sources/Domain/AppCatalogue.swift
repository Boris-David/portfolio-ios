/// The production apps that carry his work.
public struct AppCatalogue: Sendable, Hashable {
  /// The date the App Store identifiers were last re-checked. Published as-is:
  /// a verifiable figure is worth the date it was verified.
  public let verifiedOn: String
  public let items: [ProductionApp]

  public init(verifiedOn: String, items: [ProductionApp]) {
    self.verifiedOn = verifiedOn
    self.items = items
  }

  /// The ones whose ticketing layer is his.
  public var ticketing: [ProductionApp] {
    items.filter { $0.role == .ticketing }
  }
}
