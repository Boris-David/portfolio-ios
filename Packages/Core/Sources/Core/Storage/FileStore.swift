import Foundation

/// On-disk storage, serialised by an actor.
///
/// ## Why an actor rather than a lock
///
/// Two simultaneous writes to the same key means a half-written file — the kind
/// of corruption that does not reproduce and costs a day to find. A lock would
/// protect it provided everybody remembers to take it everywhere, and nothing
/// checks that; worse, a lock held across an `await` is a deadlock waiting for
/// its moment.
///
/// With an actor, isolation becomes a **property of the type**: every access
/// from outside is necessarily serialised, and forgetting is no longer possible.
/// The compiler checks it, not the reviewer.
///
/// ## Why not SwiftData
///
/// There is no relation here, no query, no migration: one payload per language,
/// written whole, read back whole. SwiftData would bring a model to describe, a
/// context to manage, a schema to migrate — to replace `Data.write(to:)`. A
/// dependency is justified by what would be worse without it; here nothing would
/// be worse.
public actor FileStore: LocalStore {
  private let directory: URL
  private let clock: any DateProviding
  private var directoryIsReady = false

  /// - Parameters:
  ///   - directory: the working directory. `Caches` by default: the system is
  ///     allowed to empty it under storage pressure, which is exactly a cache's
  ///     contract — and what keeps it out of backups.
  ///   - clock: the clock, injected so that tests never have to wait. One
  ///     protocol for the whole repository — three layers used to inject three
  ///     differently-shaped closures that meant the same thing.
  public init(
    directory: URL? = nil,
    clock: any DateProviding = SystemClock()
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
      .contentModificationDate ?? clock.now
    return StoredValue(data: data, storedAt: storedAt)
  }

  public func write(_ data: Data, for key: StorageKey) async throws(StorageError) {
    do {
      try prepareDirectory()
      // `.atomic`: the write goes through a temporary file and a rename. A
      // power cut leaves the previous version intact instead of a truncated
      // file that the next launch would read back believing it good.
      try data.write(to: url(for: key), options: [.atomic])
    } catch let error as StorageError {
      throw error
    } catch {
      throw StorageError.write("\(key.name) — \((error as NSError).localizedDescription)")
    }
  }

  public func location(of key: StorageKey) async -> URL {
    // The directory is created even when nothing has been written yet: the
    // caller is allowed to write there itself, for instance by moving a
    // download into it.
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

    // A cache has no business in an iCloud backup: it rebuilds itself, and
    // leaving it there would spend the user's quota on bytes we know how to
    // make again.
    var directory = directory
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? directory.setResourceValues(values)

    directoryIsReady = true
  }
}
