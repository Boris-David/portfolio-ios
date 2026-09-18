import Localization

extension TextCatalogue {
  /// The labels the interface itself owns: tabs, actions, states, section
  /// headings, and the settings screen.
  ///
  /// It lives with `ViewKit` — the floor of the view layer — rather than with
  /// `Presentation`, because a catalogue is read by whatever draws. What
  /// `Presentation` still owns is the **decision**: which section, which
  /// failure, which state. It hands back a case or a value; the mapping to a key
  /// is in `InterfaceText`, and the word is in the catalogue.
  ///
  /// It is `package` rather than `public`: every reader is a module of this same
  /// package, and the application has no business resolving a label itself.
  package static let interface = TextCatalogue(bundle: .module, table: "Localizable")
}
