public struct Education: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let degree: String
  public let school: String
  /// The specialism, when it says something the title does not.
  public let detail: String?
  public let startYear: Int
  public let endYear: Int

  public init(slug: String, degree: String, school: String, detail: String?, startYear: Int, endYear: Int) {
    self.slug = slug
    self.degree = degree
    self.school = school
    self.detail = detail
    self.startYear = startYear
    self.endYear = endYear
  }
}
