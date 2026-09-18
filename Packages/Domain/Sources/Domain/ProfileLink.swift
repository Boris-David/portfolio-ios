/// A public profile — GitHub, LinkedIn.
public struct ProfileLink: Sendable, Hashable, Identifiable {
  public let id: String
  public let label: String
  public let url: URLString

  public init(id: String, label: String, url: URLString) {
    self.id = id
    self.label = label
    self.url = url
  }
}
