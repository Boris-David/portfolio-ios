import SwiftUI

/// Typography — **native**, and Dynamic Type compatible by construction.
///
/// ## Why not the website's typefaces
///
/// The site is set in Fraunces and Instrument Sans. Embedding them in the app
/// would have cost two files, a load, and above all **Dynamic Type
/// compatibility**: a custom font only follows the system sizes if you wire it
/// up yourself, and that wiring is exactly what nobody remembers to test at the
/// extra-large accessibility sizes.
///
/// iOS ships two families that hold the same roles, for free:
///
/// | Role | Site | App |
/// |---|---|---|
/// | Headings | Fraunces (high-contrast serif) | **New York** — `design: .serif` |
/// | Body | Instrument Sans | **SF Pro** — `design: .default` |
/// | Code | ui-monospace | **SF Mono** — `design: .monospaced` |
///
/// This is not a compromise: an app set in New York **looks like an iOS app**,
/// where a web typeface dropped on top always looks like a web page in a shell.
///
/// ## The scale
///
/// `design/tokens.json` already carries a scale aligned with Dynamic Type —
/// base 17, like iOS. The styles below map onto it one for one, and the point
/// sizes serve only the rare places where something has to be computed.
public enum Typography {
  /// The displayed name — the one genuinely monumental occurrence.
  public static let hero = Font.system(.largeTitle, design: .serif, weight: .semibold)
  /// A section title.
  public static let title = Font.system(.title, design: .serif, weight: .semibold)
  /// A card title.
  public static let heading = Font.system(.title3, design: .serif, weight: .semibold)
  /// Body text.
  public static let body = Font.system(.body)
  /// Body, emphasised.
  public static let bodyStrong = Font.system(.body, weight: .semibold)
  /// What accompanies: subtitles, dates, places.
  public static let secondary = Font.system(.subheadline)
  /// The line above a title — uppercase, therefore letter-spaced.
  public static let eyebrow = Font.system(.caption, weight: .semibold)
  /// A caption.
  public static let caption = Font.system(.caption)
  /// A technical term quoted as such.
  public static let code = Font.system(.callout, design: .monospaced)
  /// A figure brought forward. `.rounded` because a large number in a serif
  /// turns decorative, and this one is meant to be read.
  public static let metric = Font.system(size: Tokens.TypeScale.large, weight: .semibold, design: .rounded)
}

public extension View {
  /// Letter-spacing for uppercase.
  ///
  /// Capitals need air, and the PDF résumé learned it the hard way: at
  /// `0.09 em`, `pdftotext` extracted "COMPÉT ENCES". A résumé parser then reads
  /// words that do not exist. The value has stayed measured, never eyeballed.
  func eyebrowStyle() -> some View {
    self
      .font(Typography.eyebrow)
      .textCase(.uppercase)
      .tracking(0.6)
      .foregroundStyle(Color.ink3)
  }
}

public extension View {
  /// Bounds the reading column to a comfortable width, and centres it.
  ///
  /// The typographic rule is old and platform-independent: a line reads well at
  /// around **65 characters**. Past that, the eye loses the start of the next
  /// line on its way back to the margin.
  ///
  /// On iPhone this does nothing: the screen is already narrower. On iPad,
  /// without it, a paragraph runs a thousand points wide — measured, and
  /// unreadable. The site applies exactly the same rule, in `ch`.
  ///
  /// The width is not a round number picked by eye: `TypeScale.body` × 40
  /// approximates 65 characters for a proportional face, so it follows the scale
  /// if the scale changes.
  func readableWidth() -> some View {
    frame(maxWidth: Tokens.TypeScale.body * Tokens.Layout.readingWidthInBodies)
      .frame(maxWidth: .infinity)
  }
}
