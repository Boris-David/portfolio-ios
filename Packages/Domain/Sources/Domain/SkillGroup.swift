public struct SkillGroup: Sendable, Hashable, Identifiable {
  public let id: String
  public let title: String
  public let items: [String]

  public init(id: String, title: String, items: [String]) {
    self.id = id
    self.title = title
    self.items = items
  }
}
