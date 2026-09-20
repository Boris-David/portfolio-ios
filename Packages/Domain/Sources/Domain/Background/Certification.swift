public struct Certification: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let name: String
  public let issuer: String
  public let awardedOn: YearMonth
  /// The verification URL. A certification nobody can verify is worth exactly
  /// what the word of the person announcing it is worth.
  public let verifyURL: URLString?

  public init(slug: String, name: String, issuer: String, awardedOn: YearMonth, verifyURL: URLString?) {
    self.slug = slug
    self.name = name
    self.issuer = issuer
    self.awardedOn = awardedOn
    self.verifyURL = verifyURL
  }
}
