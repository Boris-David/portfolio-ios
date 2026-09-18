/// Why the content could not be obtained.
///
/// Three cases and not one more — because each calls for a different sentence on
/// screen, and a fourth nobody could word would have no reason to exist.
public enum ContentUnavailable: Error, Sendable, Hashable {
  /// No network, or the source does not answer.
  case unreachable
  /// The source answered, but not with what was expected. The path of the
  /// offending field is carried all the way here: an "invalid content" with no
  /// location helps nobody.
  ///
  /// The reason is a **value**, not a sentence — see `MalformedReason`.
  case malformed(path: String, reason: MalformedReason)
  /// Nothing on the network, nothing cached, not even the seed. The app can
  /// show nothing at all — the only case that justifies a full error screen.
  case nothingAvailable
}
