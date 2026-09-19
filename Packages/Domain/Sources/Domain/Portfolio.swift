/// Everything the app can say about Amissan, in one value.
///
/// A single aggregate rather than eight separate resources: the source serves
/// them together, sealed by one content version. Splitting them here would
/// reopen the possibility of a screen built from two versions of the content —
/// and nobody would ever see the difference, which is exactly the problem.
public struct Portfolio: Sendable, Hashable {
  public let profile: Profile
  public let metrics: [Metric]
  public let sections: [Section]
  public let caseStudies: [CaseStudy]
  public let apps: AppCatalogue
  public let expertise: [ExpertiseTopic]
  /// One per topic, in the same order. What makes each topic checkable.
  public let deepDives: [DeepDive]
  public let architectures: ArchitectureStudy
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
    deepDives: [DeepDive],
    architectures: ArchitectureStudy,
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
    self.deepDives = deepDives
    self.architectures = architectures
    self.experience = experience
    self.background = background
    self.skills = skills
  }
}

extension Portfolio {
  /// A section's header, in the order the source gives them.
  ///
  /// Nested on purpose: a bare `Section` would collide with SwiftUI's, and
  /// "a section of what?" has no answer away from its parent.
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

public extension Portfolio {
  /// The dive that belongs to a topic, when the source published one.
  ///
  /// A lookup rather than a stored link on `ExpertiseTopic`: the topic comes
  /// from `/v1/expertise` and the dive from `/v1/deep-dives`, and joining them
  /// in the entity would mean deciding here what happens when one is missing.
  /// Answering `nil` says it plainly, once, where the screen can act on it.
  func deepDive(for topic: String) -> DeepDive? {
    deepDives.first { $0.expertise == topic }
  }
}
