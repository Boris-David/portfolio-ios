import Domain
import Foundation
import Networking
import Persistence
@testable import Data

/// Un transport qui rend ce qu'on lui a dit, et **compte** ses appels.
///
/// Le compte est l'objet du test le plus important de ce module : quatre
/// lectures du contenu ne doivent produire qu'une requête.
actor CountingClient: HTTPClient {
  private(set) var sendCount = 0
  private(set) var downloadCount = 0
  private var response: Result<HTTPResponse, HTTPError>
  private var download: Result<HTTPDownload, HTTPError>
  /// Un délai artificiel, pour que plusieurs appelants se chevauchent vraiment.
  private let delay: Duration

  init(
    response: Result<HTTPResponse, HTTPError> = .failure(.transport(description: "non configuré")),
    download: Result<HTTPDownload, HTTPError> = .failure(.transport(description: "non configuré")),
    delay: Duration = .milliseconds(30)
  ) {
    self.response = response
    self.download = download
    self.delay = delay
  }

  func send(_ request: HTTPRequest) async throws(HTTPError) -> HTTPResponse {
    sendCount += 1
    try? await Task.sleep(for: delay)
    switch response {
    case .success(let value): return value
    case .failure(let error): throw error
    }
  }

  func download(_ request: HTTPRequest) async throws(HTTPError) -> HTTPDownload {
    downloadCount += 1
    try? await Task.sleep(for: delay)
    switch download {
    case .success(let value): return value
    case .failure(let error): throw error
    }
  }
}

/// Un stockage en mémoire — les tests de `Data` parlent de politique, pas de
/// disque. Le disque a ses propres tests.
actor MemoryStore: LocalStore {
  private var values: [String: StoredValue] = [:]
  private let directory = URL(fileURLWithPath: NSTemporaryDirectory())

  init(seeded: [String: Data] = [:]) {
    for (name, data) in seeded {
      values[name] = StoredValue(data: data, storedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
  }

  func read(_ key: StorageKey) async -> StoredValue? { values[key.name] }
  func write(_ data: Data, for key: StorageKey) async throws(StorageError) {
    values[key.name] = StoredValue(data: data, storedAt: Date())
  }
  func location(of key: StorageKey) async -> URL { directory.appendingPathComponent(key.name) }
  func remove(_ key: StorageKey) async { values[key.name] = nil }
}

/// Une graine servie depuis les fixtures du test.
struct FixtureSeed: SeedProviding {
  let builtAt = Date(timeIntervalSince1970: 1_600_000_000)
  func data(for language: Language) -> Data? { Fixtures.payload(language) }
}

enum Fixtures {
  static func payload(_ language: Language) -> Data? {
    guard let url = Bundle.module.url(
      forResource: "portfolio-\(language.rawValue)",
      withExtension: "json"
    ) else { return nil }
    return try? Data(contentsOf: url)
  }

  static func response(_ language: Language, status: Int = 200) -> HTTPResponse {
    HTTPResponse(
      status: status,
      headers: HTTPHeaders(["Content-Type": "application/json"]),
      body: payload(language) ?? Data()
    )
  }

  /// La même charge, avec un champ retiré — pour vérifier que l'erreur porte le
  /// chemin exact du champ fautif.
  static func responseMissing(_ path: [String], language: Language = .french) -> HTTPResponse {
    guard var root = try? JSONSerialization.jsonObject(with: payload(language) ?? Data())
      as? [String: Any] else { return response(language) }

    func remove(_ keys: [String], from object: inout [String: Any]) {
      guard let head = keys.first else { return }
      if keys.count == 1 {
        object[head] = nil
      } else if var child = object[head] as? [String: Any] {
        remove(Array(keys.dropFirst()), from: &child)
        object[head] = child
      }
    }
    remove(path, from: &root)

    return HTTPResponse(
      status: 200,
      headers: HTTPHeaders(["Content-Type": "application/json"]),
      body: (try? JSONSerialization.data(withJSONObject: root)) ?? Data()
    )
  }
}
