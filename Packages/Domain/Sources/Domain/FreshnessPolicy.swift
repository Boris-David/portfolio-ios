/// When to consult the source, and when to settle for what is already here.
///
/// ## The rule, and why it changed
///
/// The first version served **the cache first**, then the network: two snapshots
/// on every open, and a screen that rebuilt itself. It was fast, and it was
/// dishonest — it showed dated content with the confidence of new content, for
/// as long as the network took to answer.
///
/// The rule kept is the opposite, and it fits in one sentence: **what is
/// displayed is what the source says, now.** The local copy no longer serves to
/// display *fast*, it serves to display *at all* — dropped connection, timeout,
/// aeroplane mode.
public enum FreshnessPolicy: Sendable, Hashable {
  /// The network first; the local copy **only** if it fails. The default.
  case networkFirst

  /// The local copy first if it exists and has not aged past its limit; the
  /// network otherwise.
  ///
  /// Reserved for calls whose content practically never moves. Used by
  /// exception, never by convenience: every use has to be justified, because
  /// every use is an opportunity to display something false.
  case cacheFirst(maxAge: Duration)
}
