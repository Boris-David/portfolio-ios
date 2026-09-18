import Domain

/// The initials drawn in place of a photograph.
///
/// ## Why initials and not a portrait
///
/// A portrait on a CV is a French convention and a liability everywhere else:
/// several countries' hiring guidance asks candidates not to include one,
/// precisely because it invites a judgement that has nothing to do with the
/// work. The monogram gives the screen the same anchor — something to land on
/// before the text — without that.
///
/// ## Why it is computed here
///
/// Deriving initials from a name is a **presentation** decision: which parts
/// count, what happens to a hyphenated surname, how many letters. The domain
/// holds the name; it has no opinion on how to abbreviate it.
public struct Monogram: Sendable, Hashable {
  public let letters: String

  /// Takes the first letter of the first two parts of the **display** name.
  ///
  /// The display name, not the full one: "Amissan Amoussou-G." gives AA, which
  /// is what the reader sees on screen. Using the full name would give a third
  /// letter nobody could match to anything.
  ///
  /// A hyphenated part counts once — "Amoussou-Guenou" is one surname, and AAG
  /// would be an abbreviation of something that is not there.
  public init(_ name: Profile.Name) {
    letters = name.display
      .split(separator: " ")
      .prefix(2)
      .compactMap { $0.first.map(String.init) }
      .joined()
      .uppercased()
  }
}
