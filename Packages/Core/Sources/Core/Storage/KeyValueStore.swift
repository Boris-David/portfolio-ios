/// Small, scalar values that survive a relaunch.
///
/// ## Why a port over `UserDefaults`
///
/// Not for purity: for **testability and for count**. A test must be able to
/// describe a first launch, a value already set, and a store that refuses to
/// write — three situations a hard-coded `UserDefaults.standard` makes
/// impossible to stage, because it is process-wide shared state.
///
/// And because it belongs to `Core` rather than to whoever needed it first: the
/// moment a second feature wants to remember something, it depends on this
/// protocol instead of writing its own wrapper. That is the duplication this
/// package exists to prevent.
///
/// ## Why it is not the file store
///
/// `LocalStore` keeps **bulky content the system may purge** — a cache. This
/// keeps **preferences**, which must never be purged: somebody who set the app
/// to English does not want to find it in French because the disk filled up.
/// Same mechanism, opposite contract, so two types.
public protocol KeyValueStore: Sendable {
  func string(forKey key: String) -> String?
  func bool(forKey key: String) -> Bool
  func set(_ value: String, forKey key: String)
  func set(_ value: Bool, forKey key: String)
  func removeValue(forKey key: String)
}
