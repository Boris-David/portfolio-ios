import Foundation
import Testing
@testable import Persistence

struct StorageKeyTests {
  /// The type exists so that no string from elsewhere can become a path. What
  /// it refuses matters as much as what it accepts.
  @Test("accepts a plain file name", arguments: [
    "portfolio-fr.json", "resume-en.meta.json", "amissan.ag-cv-fr.pdf",
  ])
  func accepts(_ name: String) {
    #expect(StorageKey(name) != nil)
  }

  @Test("refuses anything that could escape the directory", arguments: [
    "", ".", "..", "../secrets", "a/b.json", "a\\b", "UPPERCASE.json", "with space.json",
  ])
  func refuses(_ name: String) {
    #expect(StorageKey(name) == nil)
  }
}

struct FileStoreTests {
  private func makeStore() -> (FileStore, URL) {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("amissan-tests-\(UUID().uuidString)", isDirectory: true)
    return (FileStore(directory: directory), directory)
  }

  @Test("reads back exactly what was written")
  func roundTrip() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let key = try #require(StorageKey("content.json"))
    let payload = Data(#"{"meta":{"locale":"fr"}}"#.utf8)

    try await store.write(payload, for: key)
    let stored = await store.read(key)

    #expect(stored?.data == payload)
    #expect(stored?.storedAt != nil)
  }

  @Test("returns nil for a key never written")
  func missingIsNil() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("never-written.json"))
    #expect(await store.read(key) == nil)
  }

  @Test("a second write replaces the first")
  func overwrite() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("content.json"))

    try await store.write(Data("one".utf8), for: key)
    try await store.write(Data("two".utf8), for: key)

    #expect(await store.read(key)?.data == Data("two".utf8))
  }

  /// The location is known **before** anything is written: that is what allows
  /// a download to be moved there rather than loaded into memory.
  @Test("gives a location even with no prior write")
  func locationWithoutWrite() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("cv.pdf"))

    let url = await store.location(of: key)
    #expect(url.lastPathComponent == "cv.pdf")
    #expect(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
  }

  /// Serialised by construction: the actor makes the concurrent write that
  /// would leave a half-written file impossible.
  @Test("survives a hundred concurrent writes without corruption")
  func concurrentWrites() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("concurrent.json"))
    let payload = Data(repeating: 0x41, count: 64_000)

    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<100 {
        group.addTask { try? await store.write(payload, for: key) }
      }
    }

    #expect(await store.read(key)?.data.count == payload.count)
  }
}
