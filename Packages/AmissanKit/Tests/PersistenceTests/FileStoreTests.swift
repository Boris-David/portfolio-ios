import Foundation
import Testing
@testable import Persistence

struct StorageKeyTests {
  /// Le type existe pour qu'aucune chaîne venue d'ailleurs ne devienne un
  /// chemin. Ce qui est refusé compte autant que ce qui est accepté.
  @Test("accepte un nom de fichier sobre", arguments: [
    "portfolio-fr.json", "resume-en.meta.json", "amissan.ag-cv-fr.pdf",
  ])
  func accepts(_ name: String) {
    #expect(StorageKey(name) != nil)
  }

  @Test("refuse tout ce qui pourrait sortir du répertoire", arguments: [
    "", ".", "..", "../secrets", "a/b.json", "a\\b", "MAJUSCULES.json", "espace .json",
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

  @Test("relit exactement ce qui a été écrit")
  func roundTrip() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let key = try #require(StorageKey("contenu.json"))
    let payload = Data(#"{"meta":{"locale":"fr"}}"#.utf8)

    try await store.write(payload, for: key)
    let stored = await store.read(key)

    #expect(stored?.data == payload)
    #expect(stored?.storedAt != nil)
  }

  @Test("rend nil pour une clé jamais écrite")
  func missingIsNil() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("jamais-ecrit.json"))
    #expect(await store.read(key) == nil)
  }

  @Test("une seconde écriture remplace la première")
  func overwrite() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("contenu.json"))

    try await store.write(Data("un".utf8), for: key)
    try await store.write(Data("deux".utf8), for: key)

    #expect(await store.read(key)?.data == Data("deux".utf8))
  }

  /// L'emplacement est connu **avant** toute écriture : c'est ce qui permet d'y
  /// déplacer un téléchargement plutôt que de le charger en mémoire.
  @Test("donne un emplacement même sans écriture préalable")
  func locationWithoutWrite() async throws {
    let (store, directory) = makeStore()
    defer { try? FileManager.default.removeItem(at: directory) }
    let key = try #require(StorageKey("cv.pdf"))

    let url = await store.location(of: key)
    #expect(url.lastPathComponent == "cv.pdf")
    #expect(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
  }

  /// Sérialisé par construction : l'acteur rend impossible l'écriture
  /// concurrente qui laisserait un fichier à moitié écrit.
  @Test("supporte cent écritures concurrentes sans se corrompre")
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
