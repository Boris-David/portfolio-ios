/// A position, described by **machine facts** — not by an already-formatted
/// sentence.
///
/// `start: YearMonth(2023, 5)` and `end: nil`, never "May 2023 → today". The
/// readable string depends on the language, the context and the room available:
/// building it at the source would freeze it for every client at once, and a
/// PDF résumé does not want it the way a phone screen does.
public struct Experience: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let role: String
  public let organisation: String
  public let location: String
  public let start: YearMonth
  /// `nil` means "ongoing" — an absence, not a sentinel date.
  public let end: YearMonth?
  /// Side roles held alongside the position. Often empty, which is normal.
  public let sideRoles: [String]
  public let highlights: [RichText]
  public let stack: [String]

  public init(
    slug: String,
    role: String,
    organisation: String,
    location: String,
    start: YearMonth,
    end: YearMonth?,
    sideRoles: [String],
    highlights: [RichText],
    stack: [String]
  ) {
    self.slug = slug
    self.role = role
    self.organisation = organisation
    self.location = location
    self.start = start
    self.end = end
    self.sideRoles = sideRoles
    self.highlights = highlights
    self.stack = stack
  }

  public var isOngoing: Bool { end == nil }
}
