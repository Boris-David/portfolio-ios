import Foundation
import Testing

@testable import ViewKit

/// **Every interest the API serves gets a glyph.**
///
/// The mapping degrades gracefully — an unknown identity renders a chip with no
/// symbol, which is better than a blank square. But a graceful degradation
/// nobody watches is a silent failure: add an interest to the content and the
/// chip quietly loses its glyph while every suite stays green.
///
/// So the bundled seed is read, and every identity in it has to be known here.
/// The seed is the app's own copy of what the API serves, and `seed.sh --check`
/// already keeps it honest against production.
struct InterestGlyphTests {
  /// Read on each call rather than cached in a `static let`: a decoded JSON
  /// object is not `Sendable`, and a stored one would make this type refuse to
  /// compile under strict concurrency. The file is small and read a handful of
  /// times.
  private static var servedIdentities: [String] {
    var url = URL(fileURLWithPath: #filePath)
    // …/Packages/Features/Tests/ViewKitTests/InterestGlyphTests.swift
    for _ in 0..<4 { url.deleteLastPathComponent() }
    let file = url.appending(path: "Data/Sources/Data/Resources/seed-fr.json")

    guard let bytes = try? Data(contentsOf: file),
          let seed = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
          let data = seed["data"] as? [String: Any],
          let profile = data["profile"] as? [String: Any],
          let personality = profile["personality"] as? [String: Any],
          let interests = personality["interests"] as? [[String: Any]]
    else { return [] }

    return interests.compactMap { $0["id"] as? String }
  }

  /// The read has to be real: an empty list would make the assertion below
  /// vacuously true, which is how a guard stops guarding without saying so.
  @Test("the seed was actually read")
  func seedIsRead() {
    #expect(Self.servedIdentities.count >= 2, "found \(Self.servedIdentities)")
  }

  @Test("every interest the app is served has a glyph")
  func everyServedInterestHasAGlyph() {
    for identity in Self.servedIdentities {
      #expect(InterestGlyph.name(for: identity) != nil, "'\(identity)' has no symbol")
    }
  }

  @Test("an identity nobody declared gets nothing rather than something wrong")
  func unknownIdentityIsNotGuessed() {
    #expect(InterestGlyph.name(for: "chess") == nil)
  }
}
