/// Reports whether the device is reachable, now and as it changes.
///
/// ## Why the app needs this at all
///
/// Today "offline" is **inferred from a failure**: a request is fired, it times
/// out after fifteen seconds, and only then does the screen fall back to the
/// local copy. The person waited fifteen seconds to be told what the system knew
/// before the request left.
///
/// A monitor turns that around. When the path is known to be down, the local
/// copy is served immediately and the screen says why — and when the path comes
/// back, the screen can refresh itself without anybody pulling on it.
///
/// ## Why a stream and not just a property
///
/// Connectivity is not a value you read, it is a value that **changes under
/// you**. A property would be read once at launch and be wrong ever after. The
/// stream is what lets a banner appear and disappear on its own.
public protocol ConnectivityReporting: Sendable {
  var current: ConnectivityStatus { get async }
  /// Every change, starting with the current value so a subscriber never has to
  /// wait for the network to move before it can draw.
  var changes: AsyncStream<ConnectivityStatus> { get async }
}
