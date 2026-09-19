/// Publishes facts, and hands out streams of them.
///
/// ## Why a bus rather than more ports
///
/// A port answers a question asked by **one** caller who knows it is asking.
/// This is for the other shape: something happened, and an unknown number of
/// parts — a banner, a screen that wants to refresh, an analytics sink one day —
/// would each otherwise need a wire back to the place it happened.
///
/// The bus is what keeps those parts from knowing each other. That is its whole
/// value, and also its whole danger: `AppEvent` carries the rule that keeps it
/// from becoming a second, invisible control flow.
public protocol EventPublishing: Sendable {
  func publish(_ event: AppEvent) async
  var events: AsyncStream<AppEvent> { get async }
}
