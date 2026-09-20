/// Who he is, and the one channel to reach him through.
public struct Profile: Sendable, Hashable {
  public struct Name: Sendable, Hashable {
    /// The short form, shown everywhere.
    public let display: String
    /// The long form, kept for the footer and the résumé.
    public let formal: String

    public init(display: String, formal: String) {
      self.display = display
      self.formal = formal
    }
  }

  public struct Contact: Sendable, Hashable {
    public let email: String
    public let title: String
    public let body: String
    public let links: [ProfileLink]

    public init(email: String, title: String, body: String, links: [ProfileLink]) {
      self.email = email
      self.title = title
      self.body = body
      self.links = links
    }
  }

  public let name: Name
  public let headline: String
  public let availability: String
  public let location: String
  public let languages: String
  public let summary: [RichText]
  public let showcase: Showcase
  public let contact: Contact
  public let footer: Footer

  public init(
    name: Name,
    headline: String,
    availability: String,
    location: String,
    languages: String,
    summary: [RichText],
    showcase: Showcase,
    contact: Contact,
    footer: Footer
  ) {
    self.name = name
    self.headline = headline
    self.availability = availability
    self.location = location
    self.languages = languages
    self.summary = summary
    self.showcase = showcase
    self.contact = contact
    self.footer = footer
  }
}

extension Profile {
  /// The featured screenshot, and the case study it illustrates.
  public struct Showcase: Sendable, Hashable {
    public let media: Media
    /// What the **product** does.
    ///
    /// Separate from `media.alt`, which describes the **picture** for somebody
    /// who cannot see it. The two were one string, so the sentence a sighted
    /// reader took as a pitch was also the one VoiceOver read as a description
    /// of a screenshot — neither job was done well.
    public let description: String
    public let caseStudySlug: String?

    public init(media: Media, description: String, caseStudySlug: String?) {
      self.media = media
      self.description = description
      self.caseStudySlug = caseStudySlug
    }
  }

  public struct Footer: Sendable, Hashable {
    public let role: String
    public let location: String

    public init(role: String, location: String) {
      self.role = role
      self.location = location
    }
  }
}
