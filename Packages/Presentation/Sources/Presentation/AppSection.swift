/// The app's tabs.
public enum AppSection: String, CaseIterable, Hashable, Sendable, Identifiable {
  case profile
  case work
  case journey
  case decision

  public var id: String { rawValue }

  /// A meaning, which `ViewKit` turns into a glyph. See `Icon`.
  public var icon: Icon {
    switch self {
    case .profile: .profile
    case .work: .work
    case .journey: .journey
    case .decision: .decision
    }
  }
}
