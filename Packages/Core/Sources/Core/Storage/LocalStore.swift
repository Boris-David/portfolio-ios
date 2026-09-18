import Foundation

/// The local storage port. It knows only bytes.
public protocol LocalStore: Sendable {
  func read(_ key: StorageKey) async -> StoredValue?
  func write(_ data: Data, for key: StorageKey) async throws(StorageError)
  /// Where a file lives, whether or not anything has been written there — for
  /// documents handed to an external reader rather than read back.
  func location(of key: StorageKey) async -> URL
  func remove(_ key: StorageKey) async
}
