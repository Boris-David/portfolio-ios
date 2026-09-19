import Foundation

/// A bundle's string catalogue, read in a language **the caller names**.
///
/// ## Why this exists rather than `String(localized:)`
///
/// The standard lookup resolves against the device's preferred languages. That
/// is the right default for an application whose text is its own; it is the
/// wrong one for an application whose text is **served**, in a language the
/// reader picks, by something that may not have the device's language at all.
///
/// Left to the default, interface and content are free to disagree — and they
/// did, on the very first launch: the tabs read "Profil · Travail · Parcours"
/// above an English body. Nothing in the code was wrong; the two halves simply
/// answered to different authorities.
///
/// So here the language is an **argument**, never an ambient setting. There is
/// no call that omits it, which is what makes the disagreement unrepresentable.
///
/// ## How it reaches a language the device did not ask for
///
/// A string catalogue compiles to one `<code>.lproj` directory per language
/// inside the resource bundle. Asking the *root* bundle applies the device's
/// preference; asking the **sub-bundle** for a given `.lproj` does not. That is
/// the whole mechanism, and it is the only supported way to do this.
///
/// The sub-bundles are resolved once, at initialisation. Doing it per call
/// would open a bundle on every label of every frame.
public struct TextCatalogue: @unchecked Sendable {
  /// `Bundle` is not marked `Sendable`, and cannot be: it is a class with
  /// mutable caches. It is, however, documented as thread-safe for lookup, and
  /// what is held here is a resource bundle inside the application — read-only
  /// for its whole life, never handed out, and never mutated by this type. The
  /// checked alternative would be to re-open the bundle on every call.
  private let root: Bundle
  private let byLanguage: [String: Bundle]
  private let table: String

  /// - Parameters:
  ///   - bundle: the module's resource bundle — `.module`, at the call site of
  ///     the target that owns the catalogue.
  ///   - table: the catalogue's file name, without its extension.
  public init(bundle: Bundle, table: String) {
    self.root = bundle
    self.table = table
    self.byLanguage = bundle.localizations.reduce(into: [:]) { found, code in
      guard let path = bundle.path(forResource: code, ofType: "lproj"),
            let localized = Bundle(path: path)
      else { return }
      found[code] = localized
    }
  }

  /// The string for `key`, in `language`.
  ///
  /// A key the catalogue does not carry comes back as the key itself — the
  /// platform's behaviour, kept deliberately: it is visible on screen, and it is
  /// what `contains(_:in:)` reports on so a guard can fail the build instead.
  public func callAsFunction(_ key: String, in language: String) -> String {
    bundle(for: language).localizedString(forKey: key, value: nil, table: table)
  }

  /// The string for `key`, in `language`, varying by `count`.
  ///
  /// The plural rule is the one belonging to `language`, not to the device: a
  /// French catalogue read on an English device still puts "1 chantier" in the
  /// singular. Passing the locale is what makes that true — without it the
  /// format machinery would apply the current locale's rule to another
  /// language's text.
  public func callAsFunction(_ key: String, in language: String, count: Int) -> String {
    let format = bundle(for: language).localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale(identifier: language), arguments: [count])
  }

  /// The string for `key`, in `language`, with `arguments` substituted.
  ///
  /// The locale is the asked language's, so a number or a date interpolated into
  /// the sentence is grouped and spelled the way that language does it — not the
  /// way the device does.
  public func callAsFunction(
    _ key: String,
    in language: String,
    arguments: [any CVarArg]
  ) -> String {
    let format = bundle(for: language).localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale(identifier: language), arguments: arguments)
  }

  /// Whether the catalogue carries `key` in `language`.
  ///
  /// Exists for the guard and the tests. `localizedString` cannot say so on its
  /// own — it answers with the key — so the question is asked with a sentinel no
  /// catalogue would hold.
  public func contains(_ key: String, in language: String) -> Bool {
    let sentinel = "\u{0}missing\u{0}"
    return bundle(for: language)
      .localizedString(forKey: key, value: sentinel, table: table) != sentinel
  }

  /// The language codes the catalogue was compiled for.
  public var languages: [String] { byLanguage.keys.sorted() }

  /// The sub-bundle for `language`, or the catalogue's **source** language.
  ///
  /// Falling back to the root bundle would have been shorter, and wrong: the
  /// root honours the device's preference, so an unknown code would resolve to
  /// whatever the reader's phone is set to — the very defect this type exists to
  /// prevent, arriving through a side door. The source language is the one
  /// answer that does not depend on the device.
  private func bundle(for language: String) -> Bundle {
    byLanguage[language] ?? byLanguage[root.developmentLocalization ?? ""] ?? root
  }
}
