import Foundation

/// Le stockage sur disque, sérialisé par un acteur.
///
/// ## Pourquoi un acteur, et pas un verrou
///
/// Deux écritures simultanées sur la même clé, c'est un fichier à moitié écrit
/// — le genre de corruption qui ne se reproduit pas et qu'on passe une journée
/// à chercher. Un verrou protégerait à condition qu'on pense à le prendre
/// partout, et rien ne le vérifie ; pire, un verrou tenu pendant une attente
/// asynchrone est un blocage qui n'attend que son heure.
///
/// Avec un acteur, l'isolation devient une **propriété du type** : tout accès
/// venant de l'extérieur est nécessairement sérialisé, et l'oubli n'est plus
/// possible. Le compilateur le vérifie, pas la relecture.
///
/// ## Pourquoi pas SwiftData
///
/// Il n'y a ici ni relation, ni requête, ni migration : une charge utile par
/// langue, écrite en entier, relue en entier. SwiftData apporterait un modèle
/// à décrire, un contexte à gérer, un schéma à faire évoluer — pour remplacer
/// `Data.write(to:)`. Une dépendance se justifie par ce qui serait pire sans
/// elle ; ici, rien ne serait pire.
public actor FileStore: LocalStore {
  private let directory: URL
  private let clock: @Sendable () -> Date
  private var directoryIsReady = false

  /// - Parameters:
  ///   - directory: le répertoire de travail. `Caches` par défaut : le système
  ///     a le droit de le vider sous pression de stockage, ce qui est
  ///     exactement le contrat d'un cache — et ce qui l'exclut des sauvegardes.
  ///   - clock: l'horloge, injectée pour que les tests n'aient pas à attendre.
  public init(
    directory: URL? = nil,
    clock: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.directory = directory ?? FileStore.defaultDirectory()
    self.clock = clock
  }

  private static func defaultDirectory() -> URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("AmissanContent", isDirectory: true)
  }

  public func read(_ key: StorageKey) async -> StoredValue? {
    let url = url(for: key)
    guard let data = try? Data(contentsOf: url) else { return nil }
    let storedAt = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
      .contentModificationDate ?? clock()
    return StoredValue(data: data, storedAt: storedAt)
  }

  public func write(_ data: Data, for key: StorageKey) async throws(StorageError) {
    do {
      try prepareDirectory()
      // `.atomic` : l'écriture passe par un fichier temporaire puis un
      // renommage. Une coupure d'alimentation laisse l'ancienne version
      // intacte au lieu d'un fichier tronqué qu'on relirait au lancement
      // suivant en croyant qu'il est bon.
      try data.write(to: url(for: key), options: [.atomic])
    } catch let error as StorageError {
      throw error
    } catch {
      throw StorageError.write("\(key.name) — \((error as NSError).localizedDescription)")
    }
  }

  public func location(of key: StorageKey) async -> URL {
    // Le répertoire est créé même si rien n'y est encore écrit : l'appelant a
    // le droit d'y écrire lui-même, par exemple en y déplaçant un
    // téléchargement.
    try? prepareDirectory()
    return url(for: key)
  }

  public func remove(_ key: StorageKey) async {
    try? FileManager.default.removeItem(at: url(for: key))
  }

  // ───────────────────────────────────────────────────────────────────────

  private func url(for key: StorageKey) -> URL {
    directory.appendingPathComponent(key.name, isDirectory: false)
  }

  private func prepareDirectory() throws {
    guard !directoryIsReady else { return }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    // Un cache n'a rien à faire dans une sauvegarde iCloud : il se reconstruit
    // tout seul, et l'y laisser consommerait le quota de l'utilisateur pour
    // des octets qu'on sait refabriquer.
    var directory = directory
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? directory.setResourceValues(values)

    directoryIsReady = true
  }
}
