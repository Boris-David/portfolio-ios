import Domain

/// A value from the source that the domain cannot accept, **and where**.
///
/// The reason is a `MalformedReason` and not a sentence: this layer cannot see
/// the language the reader chose, so it must not write prose. It says what is
/// wrong; `AppChrome` says it in French or in English.
struct MappingError: Error, Sendable, Hashable {
  let path: String
  let reason: MalformedReason
}
