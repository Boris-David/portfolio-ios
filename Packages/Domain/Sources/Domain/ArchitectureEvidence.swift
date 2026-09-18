/// How many types in a codebase carry a given suffix — the measured basis of a
/// reading.
///
/// It is structured data rather than a number written inside a sentence, and
/// that is the whole point: a figure buried in prose cannot be checked, while
/// this one is pinned to what was actually measured. It says nothing about a
/// business, names no module and no client — it is the **shape of the code**,
/// which is exactly what the reading claims.
public struct ArchitectureEvidence: Sendable, Hashable, Identifiable {
  /// The suffix counted — `ViewModel`, `UseCase`. It identifies the measurement
  /// because a codebase is read once per suffix.
  public var id: String { symbol }

  public let symbol: String
  public let count: Int

  public init(symbol: String, count: Int) {
    self.symbol = symbol
    self.count = count
  }
}
