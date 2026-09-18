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

/// A piece of text in both served languages, kept **side by side**.
///
/// Two parallel arrays — one French, one English — would have let one drift
/// without the other: you fix a sentence, forget its translation, and nothing
/// says so. Here both versions sit in the same declaration, two lines apart, and
/// a test refuses an empty one.
///
/// This does not replace a string catalogue for an ordinary app. It replaces it
/// **here**, because the displayed language is the one the *source* serves, not
/// the device's — and the two must be incapable of disagreeing.
public struct Bilingual: Sendable, Hashable, ExpressibleByStringLiteral {
  public let fr: String
  public let en: String

  public init(fr: String, en: String) {
    self.fr = fr
    self.en = en
  }

  /// A string identical in both languages — a component name, an identifier.
  /// Not a forgotten translation: a string that does not need one.
  public init(stringLiteral value: String) {
    self.fr = value
    self.en = value
  }

  public func callAsFunction(_ language: Language) -> String {
    switch language {
    case .french: fr
    case .english: en
    }
  }

  public var isComplete: Bool {
    !fr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
