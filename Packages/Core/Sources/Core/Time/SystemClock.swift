import Foundation

/// The device's clock.
public struct SystemClock: DateProviding {
  public init() {}
  public var now: Date { Date() }
}
