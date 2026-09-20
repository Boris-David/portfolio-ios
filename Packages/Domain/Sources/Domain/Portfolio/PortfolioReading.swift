/// The content port.
///
/// This is one of the two contracts the screens know. They do not know a
/// network, a cache or a bundle exists — and the package graph forbids them
/// from finding out, since `Features` never declares `Networking`,
/// `Persistence` or `Data`.
public protocol PortfolioReading: Sendable {
  /// The content, under the requested policy.
  ///
  /// Returns **one** snapshot. That was not always so: the previous version
  /// returned a stream, because it served the cache and then the network. With
  /// "network first" there is only one answer to give — and a method returning a
  /// value reads, tests and composes better than a stream you take one element
  /// from.
  ///
  /// Throws **only** when nothing is available, on the network or locally. A
  /// network failure with a usable cache is not an error: it is a snapshot that
  /// says so in `refreshFailure`.
  func portfolio(
    in language: Language,
    policy: FreshnessPolicy
  ) async throws -> PortfolioSnapshot
}
