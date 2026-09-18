/// Tout ce que l'application sait dire d'Amissan, en une valeur.
///
/// Un seul agrégat plutôt que huit ressources séparées : la source les sert
/// ensemble, scellées par une même empreinte. Les découper ici rouvrirait la
/// possibilité d'afficher un écran construit sur deux versions du contenu — et
/// personne ne verrait jamais la différence, ce qui est exactement le problème.
public struct Portfolio: Sendable, Hashable {
  public let profile: Profile
  public let metrics: [Metric]
  public let sections: [Section]
  public let caseStudies: [CaseStudy]
  public let apps: AppCatalogue
  public let expertise: [ExpertiseTopic]
  public let experience: [Experience]
  public let background: Background
  public let skills: [SkillGroup]

  public init(
    profile: Profile,
    metrics: [Metric],
    sections: [Section],
    caseStudies: [CaseStudy],
    apps: AppCatalogue,
    expertise: [ExpertiseTopic],
    experience: [Experience],
    background: Background,
    skills: [SkillGroup]
  ) {
    self.profile = profile
    self.metrics = metrics
    self.sections = sections
    self.caseStudies = caseStudies
    self.apps = apps
    self.expertise = expertise
    self.experience = experience
    self.background = background
    self.skills = skills
  }
}

extension Portfolio {
  /// L'en-tête d'une section, telle que la source l'ordonne.
  public struct Section: Sendable, Hashable, Identifiable {
    public let id: String
    public let eyebrow: String
    public let title: String
    public let intro: RichText?
    public let note: RichText?

    public init(id: String, eyebrow: String, title: String, intro: RichText?, note: RichText?) {
      self.id = id
      self.eyebrow = eyebrow
      self.title = title
      self.intro = intro
      self.note = note
    }
  }

  public func section(_ id: String) -> Section? {
    sections.first { $0.id == id }
  }
}
