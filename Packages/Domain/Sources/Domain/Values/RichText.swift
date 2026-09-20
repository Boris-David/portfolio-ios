import Foundation

/// Text carrying emphasis, independent of how it will be rendered.
///
/// The source serves **typed spans** rather than a marked-up string. That choice
/// is paid for once and pays back everywhere: there is no grammar to parse, so
/// no escaping to design, so no sentence mangled by a stray `**`.
///
/// The domain knows nothing of `AttributedString`, SwiftUI or HTML. It says
/// *"this fragment matters"*, not *"this fragment is bold"* — a difference that
/// starts to count the day "matters" means a colour on screen, a weight in a
/// PDF, and an announcement in VoiceOver.
public struct RichText: Sendable, Hashable {
  public struct Span: Sendable, Hashable {
    public enum Emphasis: Sendable, Hashable {
      /// The thread of the sentence.
      case plain
      /// What a hurried reader must catch without reading the rest.
      case strong
      /// A technical term quoted as such: `actor`, `async/await`.
      case code
    }

    public let text: String
    public let emphasis: Emphasis

    public init(text: String, emphasis: Emphasis) {
      self.text = text
      self.emphasis = emphasis
    }
  }

  public let spans: [Span]

  public init(spans: [Span]) {
    self.spans = spans
  }

  /// The bare text — for accessibility labels, titles, and anything that cannot
  /// carry emphasis.
  public var plain: String {
    spans.map(\.text).joined()
  }

  public var isEmpty: Bool {
    plain.isEmpty
  }
}

extension RichText: ExpressibleByStringLiteral {
  /// A convenience for tests and previews — never for published content, which
  /// always comes from the source.
  public init(stringLiteral value: String) {
    self.init(spans: [Span(text: value, emphasis: .plain)])
  }
}
