/// A subject dug into — what he can be questioned on in depth.
public struct ExpertiseTopic: Sendable, Hashable, Identifiable {
  public let id: String
  public let title: String
  public let body: RichText

  public init(id: String, title: String, body: RichText) {
    self.id = id
    self.title = title
    self.body = body
  }
}
