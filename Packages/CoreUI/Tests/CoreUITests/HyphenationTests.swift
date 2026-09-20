import Foundation
import Testing

@testable import CoreUI

/// **Where a justified paragraph is allowed to break a word.**
///
/// The defect this exists for was visible in a capture and in nothing else:
/// with TextKit's own hyphenation the open-projects card read "In-stant
/// System". The stylesheet had already refused that case — `hyphenate-limit-
/// chars: 8 4 4` — and the factor TextKit offers cannot express a length.
struct HyphenationTests {
  private func marked(_ text: String, language: String = "fr") -> String {
    let attributed = NSMutableAttributedString(string: text)
    Hyphenation.mark(attributed, language: language)
    return attributed.string
  }

  private func breaks(in text: String, language: String = "fr") -> Int {
    marked(text, language: language).filter { $0 == "\u{00AD}" }.count
  }

  @Test("never breaks a seven-letter company name")
  func leavesShortProperNounsAlone() {
    #expect(breaks(in: "Instant System") == 0)
    #expect(breaks(in: "Inetum") == 0)
  }

  @Test("breaks a long word, because that is what keeps the spacing even")
  func breaksLongWords() {
    #expect(breaks(in: "Actuellement") > 0)
  }

  /// The rule bounds each break against the **word**, not against its
  /// neighbour: two valid opportunities can sit two letters apart, and the
  /// engine only ever uses one of them per line. So what has to hold is that
  /// the word never begins or ends with a stub.
  @Test("never leaves a stub at either end of a word")
  func honoursTheEdges() {
    for word in ["développeur", "authentification", "architecture", "billettique"] {
      let pieces = marked(word).split(separator: "\u{00AD}")
      guard pieces.count > 1 else { continue }

      #expect(pieces.first?.count ?? 0 >= Hyphenation.minimumBefore, "\(word) starts with \(pieces[0])")
      #expect(pieces.last?.count ?? 0 >= Hyphenation.minimumAfter, "\(word) ends with \(pieces[pieces.count - 1])")
    }
  }

  /// The language is an argument, never the device's. A French sentence
  /// hyphenated with an English dictionary is the same defect as a French
  /// catalogue read because the phone is French — which this app has already
  /// paid for once.
  @Test("uses the dictionary of the content's language")
  func followsTheContentLanguage() {
    let french = marked("particulièrement", language: "fr")
    let english = marked("particulièrement", language: "en")

    #expect(french != english)
  }

  @Test("leaves a string with nothing to break exactly as it was")
  func touchesNothingElse() {
    let untouched = "Un seul contenu, servi à trois surfaces."

    #expect(marked(untouched) == untouched)
  }
}
