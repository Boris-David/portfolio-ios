import Localization

/// A catalogue, already bound to the language on screen.
///
/// Callers pass a key and — when the sentence varies — a count. They never pass
/// a language, which is what makes "interface in one language, content in the
/// other" unrepresentable rather than merely discouraged.
package struct LocalizedText: Sendable {
  private let catalogue: TextCatalogue
  private let language: String

  package init(catalogue: TextCatalogue, language: String) {
    self.catalogue = catalogue
    self.language = language
  }

  package func callAsFunction(_ key: TextKey) -> String {
    catalogue(key.identifier, in: language)
  }

  /// The plural rule applied is the one belonging to the language on screen, not
  /// the device's — French puts 1 and 0 in the singular, English only 1. Written
  /// by hand, this produced "1 chantiers".
  package func callAsFunction(_ key: TextKey, count: Int) -> String {
    catalogue(key.identifier, in: language, count: count)
  }

  /// A sentence with values substituted into it.
  ///
  /// The order of the placeholders belongs to the **catalogue**, not to this
  /// call: a language that needs to put the component before the number says so
  /// with `%2$@ %1$lld`, and no Swift changes.
  package func callAsFunction(_ key: TextKey, _ arguments: any CVarArg...) -> String {
    catalogue(key.identifier, in: language, arguments: arguments)
  }

  /// Whether the catalogue carries this key at all.
  ///
  /// A note without a pitfall simply has no `…pitfall` entry: the catalogue
  /// decides what a note contains, rather than a parallel set of Swift flags
  /// that could disagree with it.
  package func has(_ key: TextKey) -> Bool {
    catalogue.contains(key.identifier, in: language)
  }
}
