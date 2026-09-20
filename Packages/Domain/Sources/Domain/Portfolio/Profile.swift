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
  public let personality: Personality
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
    personality: Personality,
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
    self.personality = personality
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

  /// Who he is when he is not writing code.
  ///
  /// Told by facts and not by adjectives: "class representative, president of
  /// the student committee, team captain" says leader without the word, and a
  /// reader can go and check it. The API refuses the adjectives outright.
  public struct Personality: Sendable, Hashable {
    /// The one fact set apart, because a reader remembers it.
    public let highlight: Highlight
    public let summary: [RichText]
    public let interests: [Interest]

    public init(highlight: Highlight, summary: [RichText], interests: [Interest]) {
      self.highlight = highlight
      self.summary = summary
      self.interests = interests
    }

    /// A distinction, and what keeps it from being self-awarded.
    ///
    /// `detail` carries the vote and the year. Without it the title is somebody
    /// handing themselves a prize; with it, it is a fact with witnesses — which
    /// is the whole reason it is publishable at all.
    public struct Highlight: Sendable, Hashable {
      public let title: String
      public let detail: String

      public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
      }
    }

    /// An interest, under an identity a client can put a glyph beside.
    ///
    /// The glyph's **name** is not here: an SF Symbol means nothing to the
    /// website and nothing at all to the résumé. The identity travels, the
    /// presentation stays at home.
    public struct Interest: Sendable, Hashable, Identifiable {
      public let id: String
      public let label: String

      public init(id: String, label: String) {
        self.id = id
        self.label = label
      }
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
