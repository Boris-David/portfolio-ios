/// Something that **has happened**, that several unrelated parts may care about.
///
/// ## The admission rule, and why it is written down
///
/// An event bus turns into spaghetti the moment commands travel on it: nobody
/// can say who triggers what any more, and the call stack stops explaining
/// anything. So the rule is narrow, and it is a rule rather than a preference:
///
/// > An event describes a **fact already in the past**, in the past tense, that
/// > **several parts with no knowledge of each other** need. An instruction —
/// > "reload", "open this" — goes through a port or a call, never through here.
///
/// Read the cases: every one of them already happened. `refreshContent` would
/// not be one; it would be an order wearing an event's clothes.
///
/// ## Why the vocabulary is here and the bus is not
///
/// These are facts about **this application**, so they belong to the domain. The
/// machine that carries them is generic and lives in `Core`, which knows nothing
/// about any of this. Putting the vocabulary in `Core` would have forced every
/// subscriber to depend on the mechanics package — and inherit access to the
/// file store along the way.
public enum AppEvent: Sendable, Hashable {
  /// New content reached the device, sealed by this version.
  case contentRefreshed(contentVersion: String)
  /// The reader chose another language, and the whole interface follows.
  case languageChanged(Language)
  /// The route to the outside world went up or down.
  ///
  /// A `Bool` and not a status enum: "can we reach anything" is all the
  /// application's vocabulary needs. Whether the path is expensive or
  /// constrained is an infrastructure detail, and it stays in `Core` with the
  /// monitor that knows it.
  case connectivityChanged(isReachable: Bool)
  /// The résumé finished downloading and is on disk under this name.
  case resumeDownloaded(fileName: String)
}
