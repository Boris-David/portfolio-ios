/// Publishes facts, and hands out streams of them.
///
/// ## Why a bus here rather than more ports
///
/// A port answers a question asked by **one** caller who knows it is asking.
/// This is for the other shape: something happened, and an unknown number of
/// parts — a banner, an analytics sink one day, a screen that wants to refresh —
/// would each otherwise need a wire back to the place it happened.
///
/// The bus is the abstraction that keeps those parts from knowing each other.
/// That is its whole value, and also its whole danger: see `AppEvent` for the
/// rule that keeps it from becoming a second, invisible control flow.
public protocol EventPublishing: Sendable {
  func publish(_ event: AppEvent) async
  /// Every event from the moment of subscription. Deliberately **not**
  /// replayed: a subscriber that needs the current state reads it from a port,
  /// because a bus is a record of changes, not a store of values.
  var events: AsyncStream<AppEvent> { get async }
}
