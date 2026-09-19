public struct OpenProject: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let name: String
  public let description: RichText
  public let sourceURL: URLString?

  public init(slug: String, name: String, description: RichText, sourceURL: URLString?) {
    self.slug = slug
    self.name = name
    self.description = description
    self.sourceURL = sourceURL
  }
}
