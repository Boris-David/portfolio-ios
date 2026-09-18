/// A key into a string catalogue.
///
/// A plain `String` would have done the job and lost the only thing that
/// matters: a key is not a sentence. Wrapping it makes the difference visible at
/// every call site, and lets the guard tell the two apart — `Text(someString)`
/// is a finding, `Text(text(someKey))` is the shape this application uses.
///
/// It stays `ExpressibleByStringLiteral` so a catalogue of keys reads as a list
/// of constants rather than a wall of `TextKey(...)`.
package struct TextKey: Sendable, Hashable, ExpressibleByStringLiteral {
  package let identifier: String

  package init(_ identifier: String) {
    self.identifier = identifier
  }

  package init(stringLiteral value: String) {
    self.identifier = value
  }
}
