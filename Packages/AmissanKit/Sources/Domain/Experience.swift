/// Un poste, décrit par des **faits machine** — pas par une phrase déjà mise en
/// forme.
///
/// `start: YearMonth(2023, 5)` et `end: nil`, jamais « mai 2023 → aujourd'hui ».
/// La chaîne lisible dépend de la langue, du contexte et de la place
/// disponible : la fabriquer à la source la figerait pour tous les clients à
/// la fois, et le CV en PDF ne la veut pas comme l'écran d'un téléphone.
public struct Experience: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let role: String
  public let organisation: String
  public let location: String
  public let start: YearMonth
  /// `nil` veut dire « en cours » — une absence, pas une date sentinelle.
  public let end: YearMonth?
  /// Les rôles annexes tenus en plus du poste. Souvent vide, et c'est normal.
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

/// Une année, éventuellement précisée d'un mois.
///
/// Ni `Date` ni `DateComponents` : les deux portent une heure, un fuseau et une
/// précision à la seconde dont un parcours professionnel n'a que faire — et une
/// date qui traverse un fuseau change de mois. Ici, « mai 2023 » vaut mai 2023
/// partout sur la planète.
public struct YearMonth: Sendable, Hashable, Comparable {
  public let year: Int
  /// 1 à 12, ou `nil` quand la source ne donne que l'année.
  public let month: Int?

  public init(year: Int, month: Int? = nil) {
    self.year = year
    self.month = month
  }

  public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
    (lhs.year, lhs.month ?? 1) < (rhs.year, rhs.month ?? 1)
  }
}
