import SwiftUI

/// The portfolio's colours, in SwiftUI form.
///
/// Every colour is **dynamic**: it carries its light value and its dark value,
/// and the system picks. That is what makes the most common defect impossible —
/// a shade defined for one theme only, unreadable on the other — without having
/// to think about it at each use.
///
/// They are built from `Tokens`, generated from `design/tokens.json`. The site
/// and the app therefore show **exactly** the same palette: not "roughly the
/// same", the same hexadecimal value.
public extension Color {
  /// The main ground — warm paper.
  static let paper = Color(Tokens.Color.paper)
  /// A slightly recessed ground, for surfaces laid on top.
  static let paper2 = Color(Tokens.Color.paper2)
  /// The deepest recess — chips, fields, inert areas.
  static let paper3 = Color(Tokens.Color.paper3)

  /// The hairline that separates without walling off.
  static let line = Color(Tokens.Color.line)
  /// A firmer line, kept for separations that carry meaning.
  static let line2 = Color(Tokens.Color.line2)

  /// Ink — the main text.
  static let ink = Color(Tokens.Color.ink)
  /// Secondary ink, for what accompanies.
  static let ink2 = Color(Tokens.Color.ink2)
  /// Tertiary ink: captions, metadata, what gets read second.
  static let ink3 = Color(Tokens.Color.ink3)

  /// The accent — one indigo, and one only, for what can be acted on.
  static let accent = Color(Tokens.Color.accent)
  /// The pressed accent.
  static let accentDeep = Color(Tokens.Color.accentD)
  /// The washed accent, for tinted grounds.
  static let accentWash = Color(Tokens.Color.accentW)
  /// What is written **on** the accent.
  static let onAccent = Color(Tokens.Color.onAccent)

  /// The green of successful states. Kept apart from the accent: a semantic
  /// colour and a brand colour must not be confused, or "succeeded" and
  /// "tappable" start to look alike.
  static let ok = Color(Tokens.Color.ok)

  init(_ palette: Tokens.Palette) {
    self = Color(uiColor: UIColor { traits in
      UIColor(traits.userInterfaceStyle == .dark ? palette.dark : palette.light)
    })
  }
}

private extension UIColor {
  convenience init(_ components: Tokens.Components) {
    self.init(
      red: components.red,
      green: components.green,
      blue: components.blue,
      alpha: 1
    )
  }
}
