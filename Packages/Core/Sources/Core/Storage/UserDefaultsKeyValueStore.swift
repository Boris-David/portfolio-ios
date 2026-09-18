import Foundation

/// `UserDefaults`, behind the port.
///
/// The **one** place in the repository that names `UserDefaults`. Anything else
/// that needs to remember a scalar depends on `KeyValueStore`.
///
/// ## Why `@unchecked Sendable`, and why that is not a shortcut
///
/// Apple documents `UserDefaults` as **thread-safe**, and it has been since it
/// was `NSUserDefaults`. What it is not is *annotated*: the SDK has never marked
/// it `Sendable`, so the compiler cannot know.
///
/// `@unchecked` is the right tool for exactly this gap — a guarantee that holds
/// but that the compiler cannot verify. What makes it honest rather than a
/// silencer is that the claim is written here, once, in the one type that
/// touches `UserDefaults`. The alternative — rebuilding an instance on every
/// call — would trade a documented guarantee for a measurable cost and no extra
/// safety.
public struct UserDefaultsKeyValueStore: KeyValueStore, @unchecked Sendable {
  private let defaults: UserDefaults

  public init(suiteName: String? = nil) {
    // The instance is built here rather than taken as a parameter: `UserDefaults`
    // is not `Sendable`, and handing one across an isolation boundary is a data
    // race the compiler is right to refuse. A suite name is a `String`, and it
    // travels anywhere.
    defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
  }

  public func string(forKey key: String) -> String? { defaults.string(forKey: key) }
  public func bool(forKey key: String) -> Bool { defaults.bool(forKey: key) }
  public func set(_ value: String, forKey key: String) { defaults.set(value, forKey: key) }
  public func set(_ value: Bool, forKey key: String) { defaults.set(value, forKey: key) }
  public func removeValue(forKey key: String) { defaults.removeObject(forKey: key) }
}
