import Foundation

/// A value read back from disk, with the date it was written.
///
/// The date is not decoration: it is what allows "content from 14 March" rather
/// than "possibly stale content", and what decides whether a refresh is worth
/// attempting.
public struct StoredValue: Sendable, Hashable {
  public let data: Data
  public let storedAt: Date

  public init(data: Data, storedAt: Date) {
    self.data = data
    self.storedAt = storedAt
  }
}
