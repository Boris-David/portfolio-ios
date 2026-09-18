import Foundation

/// An HTTP response, body included.
public struct HTTPResponse: Sendable, Hashable {
  public let status: Int
  public let headers: HTTPHeaders
  public let body: Data

  public init(status: Int, headers: HTTPHeaders, body: Data) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  public var isSuccess: Bool { (200..<300).contains(status) }
  /// The content has not changed: what we hold locally is still good.
  public var isNotModified: Bool { status == 304 }
}
