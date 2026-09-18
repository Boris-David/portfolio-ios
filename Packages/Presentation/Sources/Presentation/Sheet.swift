/// What presents on top, without leaving the screen.
public enum Sheet: Identifiable, Hashable, Sendable {
  case contact
  case settings

  public var id: Self { self }
}
