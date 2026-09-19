import Foundation

/// A clock that does not move — and can be pushed.
///
/// It ships in `Core` rather than in each test target on purpose: a double that
/// every layer needs is itself an abstraction, and three copies of it drift the
/// same way three closures did.
public final class FixedClock: DateProviding, @unchecked Sendable {
  private let lock = NSLock()
  private var instant: Date

  public init(_ instant: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
    self.instant = instant
  }

  public var now: Date {
    lock.withLock { instant }
  }

  /// Moves time forward. The only way this clock ever changes.
  public func advance(by interval: TimeInterval) {
    lock.withLock { instant += interval }
  }
}
