import Core
import Domain
import Foundation
import Networking
@testable import Data

/// A transport that returns what it was told to, and **counts** its calls.
///
/// The count is the subject of this module's most important test: four reads of
/// the content must produce one request.
actor HTTPClientSpy: HTTPClient {
  private(set) var sendCount = 0
  private(set) var downloadCount = 0
  private var response: Result<HTTPResponse, HTTPError>
  private var download: Result<HTTPDownload, HTTPError>
  /// An artificial delay, so that several callers genuinely overlap.
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

/// In-memory storage — `Data`'s tests are about policy, not about disks. The
/// disk has tests of its own.
actor LocalStoreStub: LocalStore {
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

/// A seed served from the test's fixtures.
struct SeedDataSourceStub: SeedProviding {
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

  /// The same payload with one field removed — to check that the failure
  /// carries the exact path of the offending field.
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
