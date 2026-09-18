import Foundation

/// A store that forgets when the process ends — for tests and previews.
public final class InMemoryKeyValueStore: KeyValueStore, @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String: Any] = [:]

  public init(_ initial: [String: Any] = [:]) {
    storage = initial
  }

  public func string(forKey key: String) -> String? {
    lock.withLock { storage[key] as? String }
  }

  public func bool(forKey key: String) -> Bool {
    lock.withLock { storage[key] as? Bool ?? false }
  }

  public func set(_ value: String, forKey key: String) {
    lock.withLock { storage[key] = value }
  }

  public func set(_ value: Bool, forKey key: String) {
    lock.withLock { storage[key] = value }
  }

  public func removeValue(forKey key: String) {
    lock.withLock { storage[key] = nil }
  }
}
