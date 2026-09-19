/// A subject dug into, at length — the essay behind a topic on the profile.
///
/// ## Why this exists as its own entity
///
/// `ExpertiseTopic` is a promise: three lines saying *I can be questioned on
/// this for an hour*. On its own it is a claim like any other, and a reader has
/// no way to weigh it. This is what makes the claim checkable — the reasoning,
/// what it rules out, and a pointer to the place in a case study where it was
/// actually done.
///
/// The profile lists the topics; touching one opens the dive. Until 2026-09-18
/// that touch opened **nothing**: the route existed, the API served the content,
/// and no screen had ever been written. The resolver's `default:` swallowed it
/// in silence, which is why the compiler now refuses one.
public struct DeepDive: Sendable, Hashable, Identifiable {
  /// One heading and the body under it.
  public struct Section: Sendable, Hashable, Identifiable {
    public var id: String { slug }
    /// Stable across languages: it identifies the section, it does not name it.
    public let slug: String
    public let heading: String
    public let blocks: [ProseBlock]

    public init(slug: String, heading: String, blocks: [ProseBlock]) {
      self.slug = slug
      self.heading = heading
      self.blocks = blocks
    }
  }

  /// Where this was actually done, so the essay is not only an argument.
  ///
  /// Two slugs rather than a resolved chapter: the dive does not own the case
  /// study, and holding a copy of it would be a second version of something the
  /// portfolio already carries once.
  public struct Evidence: Sendable, Hashable {
    public let caseStudy: String
    public let chapter: String

    public init(caseStudy: String, chapter: String) {
      self.caseStudy = caseStudy
      self.chapter = chapter
    }
  }

  /// The `ExpertiseTopic` this belongs to — and the identity of the dive, since
  /// there is exactly one per topic.
  public var id: String { expertise }
  public let expertise: String
  /// The opening, before any heading.
  public let lede: RichText
  public let sections: [Section]
  public let evidence: Evidence?

  public init(
    expertise: String,
    lede: RichText,
    sections: [Section],
    evidence: Evidence?
  ) {
    self.expertise = expertise
    self.lede = lede
    self.sections = sections
    self.evidence = evidence
  }
}
