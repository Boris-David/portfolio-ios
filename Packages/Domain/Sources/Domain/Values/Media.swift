/// A screenshot, named by identifier rather than by file name.
///
/// The domain does not know a `.jpg` exists. The presentation layer decides
/// whether `journal` becomes `journal.jpg` in a bundle or a remote URL — and it
/// alone.
public struct Media: Sendable, Hashable, Identifiable {
  public let id: String
  public let alt: String
  public let caption: String

  public init(id: String, alt: String, caption: String) {
    self.id = id
    self.alt = alt
    self.caption = caption
  }
}
