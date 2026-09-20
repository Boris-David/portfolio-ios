import Domain
import Foundation

/// A language, named in **its own** language.
///
/// ## Why not a catalogue key
///
/// Because this label says which language a *document* is written in, and it is
/// read by somebody who may not read the language the interface is in. An
/// English-speaking recruiter looking at the French résumé is better served by
/// "Français" than by "French": the word they see is the word printed on the
/// document in front of them.
///
/// The endonym is also the one form that needs no maintenance. A pair of
/// catalogue keys would be two entries per language, growing as the square of
/// the languages supported, each of which can drift.
///
/// ## Why it is not a `switch` in a view
///
/// Stated by the author, and it is the rule the whole localisation design rests
/// on: *"no screen may branch on a language."* At any instant a screen has one
/// language and does not get to ask which. `Foundation` already knows every
/// language's own name, so nothing here enumerates them either — adding a
/// language adds no line to this file.
public struct LanguageStyle: Sendable {
  private let language: Language

  public init(language: Language) {
    self.language = language
  }

  /// "Français", "English" — capitalised in the language's own conventions.
  ///
  /// Falls back to the code itself, which is a poor label and an honest one: a
  /// language whose name the system does not know would otherwise render as an
  /// empty string, and an empty label reads as a defect in the layout rather
  /// than as a gap in the data.
  public var endonym: String {
    let locale = Locale(identifier: language.rawValue)
    guard let name = locale.localizedString(forLanguageCode: language.rawValue) else {
      return language.rawValue.uppercased()
    }
    return name.capitalized(with: locale)
  }
}
