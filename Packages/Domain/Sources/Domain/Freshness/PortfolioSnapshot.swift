/// The content, its fingerprint, and what is known about its freshness.
public struct PortfolioSnapshot: Sendable, Hashable {
  public let portfolio: Portfolio
  /// The version sealed by the source. Two snapshots with the same version
  /// carry the same content, whatever their origin.
  public let contentVersion: String
  public let origin: ContentOrigin
  /// Non-nil when local content is shown **because** the refresh failed. The
  /// distinction matters: "I have not tried yet" and "I tried and could not"
  /// are not said the same way on screen.
  public let refreshFailure: ContentUnavailable?

  public init(
    portfolio: Portfolio,
    contentVersion: String,
    origin: ContentOrigin,
    refreshFailure: ContentUnavailable? = nil
  ) {
    self.portfolio = portfolio
    self.contentVersion = contentVersion
    self.origin = origin
    self.refreshFailure = refreshFailure
  }

  /// True when what is displayed was not just obtained from the source.
  public var isStale: Bool {
    if case .network = origin { false } else { true }
  }
}
