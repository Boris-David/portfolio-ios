import Domain
import Foundation

/// Where the bundled seed comes from.
///
/// A port rather than direct bundle access: the tests must be able to describe a
/// first launch with no network **and** no file, which a hard-coded
/// `Bundle.main` would make impossible.
public protocol SeedProviding: Sendable {
  func data(for language: Language) -> Foundation.Data?
  var builtAt: Date { get }
}
