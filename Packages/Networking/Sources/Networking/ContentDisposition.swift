import Foundation

/// The file name the server announces.
///
/// There are two ways to write it, and both have to be read:
///
/// ```
/// Content-Disposition: inline; filename="amissan.ag-cv-fr.pdf"
/// Content-Disposition: attachment; filename*=UTF-8''amissan.ag-cv-fr.pdf
/// ```
///
/// The second (RFC 5987) exists because the first cannot carry non-ASCII
/// characters. When both are present, **`filename*` wins**: it is the precise
/// form, the other being a fallback for older clients.
///
/// Why not simply take the last path component of the URL? Because it is the
/// **source** that decides what its document is called, and it may serve
/// `/v1/cv/fr.pdf` while naming it `amissan.ag-cv-fr.pdf`. The web learned this
/// the hard way: Safari on iOS ignores this header and names a share after the
/// URL — the résumé arrived called "fr".
public enum ContentDisposition {
  public static func fileName(in headers: HTTPHeaders) -> String? {
    guard let raw = headers["Content-Disposition"] else { return nil }
    return extended(from: raw) ?? quoted(from: raw) ?? bare(from: raw)
  }

  /// `filename*=UTF-8''encoded%20name.pdf`
  private static func extended(from raw: String) -> String? {
    guard let range = raw.range(of: "filename*=", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != ";" }
    // `charset'language'value` — the language is ignored, it serves nothing here.
    let parts = value.split(separator: "'", maxSplits: 2, omittingEmptySubsequences: false)
    guard parts.count == 3 else { return nil }
    return sanitised(String(parts[2]).removingPercentEncoding ?? String(parts[2]))
  }

  /// `filename="name.pdf"`
  private static func quoted(from raw: String) -> String? {
    guard let range = raw.range(of: "filename=\"", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != "\"" }
    return sanitised(String(value))
  }

  /// `filename=name.pdf` — unquoted, which the standard tolerates.
  private static func bare(from raw: String) -> String? {
    guard let range = raw.range(of: "filename=", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != ";" }
    return sanitised(String(value).trimmingCharacters(in: .whitespaces))
  }

  /// A name that came off the network is **untrusted input**.
  ///
  /// A server announcing `../../Library/Preferences/something.plist` would
  /// write outside the sandbox if it were copied as-is. Only the last component
  /// is kept, and anything that does not look like a file name is refused.
  private static func sanitised(_ candidate: String) -> String? {
    let name = (candidate as NSString).lastPathComponent
    guard !name.isEmpty, name != ".", name != ".." else { return nil }
    guard !name.contains("/"), !name.contains("\0") else { return nil }
    return name
  }
}
