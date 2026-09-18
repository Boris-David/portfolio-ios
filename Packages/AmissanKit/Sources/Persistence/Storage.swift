import Foundation

/// Une clé de stockage — un nom de fichier sûr, garanti par construction.
///
/// Le type existe pour qu'aucune chaîne venue d'ailleurs ne devienne un chemin.
/// Une clé se déclare ici, dans le code, et jamais depuis une réponse réseau.
public struct StorageKey: Sendable, Hashable {
  public let name: String

  /// - Important: réservé aux clés **littérales** du code. Les caractères hors
  ///   `[a-z0-9._-]` sont refusés à la construction, ce qui rend un `../`
  ///   impossible plutôt qu'improbable.
  public init?(_ name: String) {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    guard !name.isEmpty,
          name.unicodeScalars.allSatisfy(allowed.contains),
          name != ".", name != ".."
    else { return nil }
    self.name = name
  }
}

/// Une valeur relue du disque, avec la date de son enregistrement.
///
/// La date n'est pas décorative : c'est elle qui permet de dire « contenu du
/// 14 mars » plutôt que « contenu peut-être périmé », et de décider si un
/// rafraîchissement vaut la peine d'être tenté.
public struct StoredValue: Sendable, Hashable {
  public let data: Data
  public let storedAt: Date

  public init(data: Data, storedAt: Date) {
    self.data = data
    self.storedAt = storedAt
  }
}

public enum StorageError: Error, Sendable {
  case write(String)
  case read(String)
}

/// Le port du stockage local. Il ne connaît que des octets.
public protocol LocalStore: Sendable {
  func read(_ key: StorageKey) async -> StoredValue?
  func write(_ data: Data, for key: StorageKey) async throws(StorageError)
  /// L'emplacement d'un fichier, qu'on y ait déjà écrit ou non — pour les
  /// documents qu'on remet à un lecteur externe plutôt que de relire.
  func location(of key: StorageKey) async -> URL
  func remove(_ key: StorageKey) async
}
