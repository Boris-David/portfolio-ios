/// The transport port.
///
/// ## Why not Alamofire
///
/// This is not a stand against the library, which is very good. It is that
/// **what it brings is not used here**:
///
/// - *request chaining and validation* — this protocol has two methods, and
///   validation is one status comparison;
/// - *`async/await`* — `URLSession` has shipped it natively since iOS 15;
/// - *interceptors and retries* — those live in the `Data` layer, next to the
///   freshness policy, because retrying is a product decision ("how long does a
///   recruiter wait?") and not a transport one;
/// - *multipart and upload* — this app only reads.
///
/// What it would cost is real, though: one more dependency to audit on a public
/// repository, a larger binary, an API surface to explain out loud, and version
/// bumps to follow for code that does not change.
///
/// **The general rule**: a dependency is justified by what would be worse
/// without it, never by what it makes convenient. It would be worse without
/// Lottie — nobody rewrites a vector animation engine. It is not worse without
/// Alamofire.
///
/// And the protocol is what makes the choice **reversible**: the day the app
/// needs what Alamofire brings, one more implementation is enough, and not a
/// single view moves.
public protocol HTTPClient: Sendable {
  /// Sends, and waits for the complete response.
  func send(_ request: HTTPRequest) async throws(HTTPError) -> HTTPResponse

  /// Writes the response body **to a file** rather than into memory.
  ///
  /// A PDF of several megabytes has no business passing through RAM: `PDFView`
  /// and the share sheet both read a URL. The temporary file returned is the
  /// caller's to move — `URLSession` deletes it as soon as this returns.
  func download(_ request: HTTPRequest) async throws(HTTPError) -> HTTPDownload
}
