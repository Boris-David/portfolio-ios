/// What can go wrong at the transport level, and nothing else.
///
/// No case mentions the portfolio: this layer does not know what it carries.
/// That is what lets it be tested knowing nothing of the domain — and replaced
/// without reopening a line anywhere else.
public enum HTTPError: Error, Sendable, Hashable {
  /// Nothing left, or nothing came back: no network, unreachable host, timeout.
  case transport(description: String)
  /// The server answered, with a status nothing can be done with.
  case status(Int)
  /// The response is not an HTTP response — a theoretical `URLSession` case,
  /// which we decline to handle with an `as!`.
  case notHTTP
}

extension HTTPError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .transport(let description): "transport — \(description)"
    case .status(let code): "HTTP status \(code)"
    case .notHTTP: "non-HTTP response"
    }
  }
}
