/// The architecture dossier: the patterns compared, and the codebases read.
public struct ArchitectureDossier: Sendable, Hashable {
  /// The date the counts were taken from the repositories, published as it
  /// arrives.
  ///
  /// It dates the measurements the way `AppCatalogue.verifiedOn` dates the App
  /// Store identifiers, and for the same reason: a count is worth exactly what
  /// its date is worth, because the codebase keeps moving after the reading.
  public let verifiedOn: String
  public let intro: RichText
  public let patterns: [ArchitecturePattern]
  public let projects: [ProjectArchitecture]

  public init(
    verifiedOn: String,
    intro: RichText,
    patterns: [ArchitecturePattern],
    projects: [ProjectArchitecture]
  ) {
    self.verifiedOn = verifiedOn
    self.intro = intro
    self.patterns = patterns
    self.projects = projects
  }
}
