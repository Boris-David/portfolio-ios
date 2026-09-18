/// The app's tabs.
public enum AppSection: String, CaseIterable, Hashable, Sendable, Identifiable {
  case profile
  case work
  case journey
  case decision

  public var id: String { rawValue }

  /// The label comes from the chrome, therefore from the displayed language —
  /// not from here. An enum carrying its own strings would carry them in one
  /// language, and somebody would have to remember on the day a second is added.
  public func title(_ chrome: AppChrome) -> String {
    switch self {
    case .profile: chrome.tabProfile
    case .work: chrome.tabWork
    case .journey: chrome.tabJourney
    case .decision: chrome.tabEngineering
    }
  }

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
