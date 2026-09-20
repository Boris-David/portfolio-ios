import Foundation

/// The result of a download: where the bytes are, and what the server said
/// about them.
public struct HTTPDownload: Sendable {
  public let status: Int
  public let headers: HTTPHeaders
  /// `nil` on a `304`: there is no body, and that is the good news.
  public let temporaryURL: URL?

  public init(status: Int, headers: HTTPHeaders, temporaryURL: URL?) {
    self.status = status
    self.headers = headers
    self.temporaryURL = temporaryURL
  }

  public var isSuccess: Bool { (200..<300).contains(status) }
  public var isNotModified: Bool { status == 304 }
}
