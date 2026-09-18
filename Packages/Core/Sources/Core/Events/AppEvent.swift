import Foundation

/// Something that **has happened**, that several unrelated parts may care about.
///
/// ## The admission rule, and why it is written down
///
/// An event bus turns into spaghetti the moment commands travel on it: nobody
/// can say any more who triggers what, and the call stack stops explaining
/// anything. So the rule is narrow and it is a rule, not a preference:
///
/// > An event describes a **fact already in the past**, in the past tense, that
/// > **several parts with no knowledge of each other** need. An instruction —
/// > "reload", "open this" — goes through a port or a call, never through here.
///
/// Read the cases below: every one of them is something that already happened.
/// `refreshContent` would not be; it would be an order wearing an event's
/// clothes.
public enum AppEvent: Sendable, Hashable {
  /// New content reached the device, sealed by this version.
  case contentRefreshed(contentVersion: String)
  /// The reader chose another language, and the whole interface follows.
  case languageChanged
  /// The route to the outside world went up or down.
  case connectivityChanged(ConnectivityStatus)
  /// The résumé finished downloading and is on disk under this name.
  case resumeDownloaded(fileName: String)
}
