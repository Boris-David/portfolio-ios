/// Qui il est, et par quel canal on le joint.
public struct Profile: Sendable, Hashable {
  public struct Name: Sendable, Hashable {
    /// La forme courte, celle qui s'affiche partout.
    public let display: String
    /// La forme longue, réservée au pied de page et au CV.
    public let full: String

    public init(display: String, full: String) {
      self.display = display
      self.full = full
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
  public let remote: String
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
    remote: String,
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
    self.remote = remote
    self.languages = languages
    self.summary = summary
    self.showcase = showcase
    self.contact = contact
    self.footer = footer
  }
}

extension Profile {
  /// La capture mise en avant, et l'étude de cas qu'elle illustre.
  public struct Showcase: Sendable, Hashable {
    public let media: Media
    public let caseStudySlug: String?

    public init(media: Media, caseStudySlug: String?) {
      self.media = media
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

/// Un profil public — GitHub, LinkedIn.
public struct ProfileLink: Sendable, Hashable, Identifiable {
  public let id: String
  public let label: String
  public let url: URLString

  public init(id: String, label: String, url: URLString) {
    self.id = id
    self.label = label
    self.url = url
  }
}

/// Une capture, désignée par son identifiant plutôt que par un nom de fichier.
///
/// Le domaine ne sait pas qu'un `.jpg` existe. C'est la couche de présentation
/// qui décide si `journal` devient `journal.jpg` dans un bundle ou une URL
/// distante — et elle seule.
public struct Media: Sendable, Hashable, Identifiable {
  public let id: String
  public let alt: String
  public let caption: String

  public init(id: String, alt: String, caption: String) {
    self.id = id
    self.alt = alt
    self.caption = caption
  }
}

/// Une URL, gardée comme chaîne dans le domaine.
///
/// `Foundation.URL` est un type de plateforme : le domaine n'a pas à en
/// dépendre, et surtout pas à décider qu'une URL mal formée est impossible. La
/// validation est un geste d'adaptateur, elle a lieu dans `Data`.
public typealias URLString = String
