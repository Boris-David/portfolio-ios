import Localization

public extension TextCatalogue {
  /// The interface labels every screen shares: tabs, actions, states, section
  /// headings.
  ///
  /// It lives with `ViewKit` — the floor of the view layer — rather than with
  /// `Presentation`, because a catalogue is read by whoever draws. What
  /// `Presentation` still owns is the *decision*: which section, which failure,
  /// which state. It hands back a `TextKey`; this turns it into a sentence.
  static let chrome = TextCatalogue(bundle: .module, table: "Localizable")
}
