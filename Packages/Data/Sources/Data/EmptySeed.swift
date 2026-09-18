import Domain
import Foundation

/// No seed at all — for the tests that describe a bare first launch.
public struct EmptySeed: SeedProviding {
  public let builtAt = Date.distantPast
  public init() {}
  public func data(for language: Language) -> Data? { nil }
}
