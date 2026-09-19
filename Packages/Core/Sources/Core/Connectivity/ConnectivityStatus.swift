/// Whether the device can currently reach anything.
///
/// Three cases and not two: `unknown` is the state before the first path update
/// arrives, and it is **not** the same as offline. Treating it as offline would
/// show an "you are offline" banner for the first fraction of a second of every
/// launch — the classic flash that makes an app feel broken before it has done
/// anything wrong.
public enum ConnectivityStatus: Sendable, Hashable {
  case unknown
  case online(isExpensive: Bool)
  case offline

  /// True only when we **know** there is no route. `unknown` answers false:
  /// not knowing is not a reason to stop trying.
  public var isKnownOffline: Bool {
    self == .offline
  }
}
