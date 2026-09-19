import Foundation
import Testing
@testable import Networking

/// The file name the server announces.
///
/// This is **the** detail that decides what a share's recipient sees. The
/// website learned it the hard way: served from `/v1/cv/fr.pdf`, the résumé
/// arrived called "fr".
struct ContentDispositionTests {
  private func headers(_ value: String) -> HTTPHeaders {
    HTTPHeaders(["Content-Disposition": value])
  }

  @Test("reads the quoted form")
  func quoted() {
    let name = ContentDisposition.fileName(in: headers(#"inline; filename="amissan.ag-cv-fr.pdf""#))
    #expect(name == "amissan.ag-cv-fr.pdf")
  }

  @Test("reads the unquoted form")
  func bare() {
    #expect(ContentDisposition.fileName(in: headers("attachment; filename=cv.pdf")) == "cv.pdf")
  }

  @Test("reads the extended form, percent-decoded")
  func extended() {
    let name = ContentDisposition.fileName(
      in: headers("attachment; filename*=UTF-8''curriculum%20vit%C3%A6.pdf")
    )
    #expect(name == "curriculum vitæ.pdf")
  }

  /// `filename*` is the precise form; `filename` is only a fallback for older
  /// clients. When both are there, the precise one wins.
  @Test("prefers the extended form when both are present")
  func extendedWins() {
    let name = ContentDisposition.fileName(
      in: headers(#"attachment; filename="fallback.pdf"; filename*=UTF-8''precise.pdf"#)
    )
    #expect(name == "precise.pdf")
  }

  @Test("is insensitive to the header's case")
  func caseInsensitiveHeader() {
    let name = ContentDisposition.fileName(in: HTTPHeaders(["content-disposition": "inline; filename=x.pdf"]))
    #expect(name == "x.pdf")
  }

  @Test("returns nil when the header is absent")
  func absent() {
    #expect(ContentDisposition.fileName(in: HTTPHeaders([:])) == nil)
  }

  /// ⚠️ A name off the network is **untrusted input**. A hostile server
  /// announcing a path would write outside the sandbox if it were copied as-is.
  @Test("refuses anything that looks like a path", arguments: [
    #"attachment; filename="../../secrets.plist""#,
    #"attachment; filename="/etc/passwd""#,
    #"attachment; filename="..""#,
    #"attachment; filename=".""#,
  ])
  func refusesTraversal(_ header: String) {
    let name = ContentDisposition.fileName(in: headers(header))
    #expect(name == nil || !(name ?? "").contains("/"))
    #expect(name != ".." && name != ".")
  }
}

struct HTTPHeadersTests {
  /// `URLSession` returns `Content-Disposition` from some servers and
  /// `content-disposition` from others. An ordinary dictionary would be caught
  /// out one day, with nothing having changed on our side.
  @Test("reads a header whatever its case")
  func caseInsensitive() {
    let headers = HTTPHeaders(["ETag": "\"abc\"", "content-type": "application/pdf"])
    #expect(headers["etag"] == "\"abc\"")
    #expect(headers["Content-Type"] == "application/pdf")
    #expect(headers.entityTag == "\"abc\"")
  }
}

struct HTTPRequestTests {
  private let url = URL(string: "https://api.amissan.dev/v1/cv/amissan.ag-cv-fr.pdf")!

  @Test("adds If-None-Match when an entity tag is known")
  func revalidates() {
    let request = HTTPRequest(url: url).revalidating(entityTag: "\"abc\"")
    #expect(request.headers["If-None-Match"] == "\"abc\"")
  }

  /// Sending an empty `If-None-Match:` would fetch a full `200`, which is the
  /// opposite of what is wanted.
  @Test("adds nothing when the entity tag is missing", arguments: [nil, ""])
  func skipsEmptyTag(_ tag: String?) {
    #expect(HTTPRequest(url: url).revalidating(entityTag: tag).headers.isEmpty)
  }
}
