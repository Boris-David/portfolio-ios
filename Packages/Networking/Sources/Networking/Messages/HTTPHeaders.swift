/// Headers, **case-insensitive** — as the standard requires.
///
/// A plain `[String: String]` would have been caught out: `URLSession` returns
/// `Content-Disposition` from some servers and `content-disposition` from
/// others, and one day the lookup returns `nil` with nothing having changed on
/// our side. That is the kind of bug you do not reproduce.
public struct HTTPHeaders: Sendable, Hashable {
  private let storage: [String: String]

  public init(_ fields: [String: String]) {
    storage = Dictionary(
      fields.map { ($0.key.lowercased(), $0.value) },
      uniquingKeysWith: { _, last in last }
    )
  }

  public subscript(name: String) -> String? {
    storage[name.lowercased()]
  }

  public var entityTag: String? { self["ETag"] }
}
