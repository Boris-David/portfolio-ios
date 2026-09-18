import Foundation

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
