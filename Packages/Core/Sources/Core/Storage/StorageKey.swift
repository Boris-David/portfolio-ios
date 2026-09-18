import Foundation

/// A storage key — a safe file name, guaranteed by construction.
///
/// The type exists so that no string from elsewhere can become a path. A key is
/// declared here, in code, and never from a network response.
public struct StorageKey: Sendable, Hashable {
  public let name: String

  /// - Important: reserved for **literal** keys in code. Characters outside
  ///   `[a-z0-9._-]` are refused at construction, which makes a `../`
  ///   impossible rather than unlikely.
  public init?(_ name: String) {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    guard !name.isEmpty,
          name.unicodeScalars.allSatisfy(allowed.contains),
          name != ".", name != ".."
    else { return nil }
    self.name = name
  }
}
