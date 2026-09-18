/// Un projet raconté : le problème, la décision, le résultat.
///
/// Un seul type pour les deux mises en page du portfolio. Ce qui les distingue
/// n'est pas une propriété technique mais une **propriété du récit** : un
/// chapitre qui porte un titre est un chantier qu'on peut nommer et déplier ;
/// un chapitre anonyme est le corps unique d'une histoire.
///
/// Compter les chapitres aurait marché aujourd'hui et cassé au premier récit à
/// deux chapitres anonymes.
public struct CaseStudy: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let title: String
  public let subtitle: String
  public let intro: RichText?
  public let link: Link?
  public let media: [Media]
  public let chapters: [Chapter]
  public let tags: [String]

  public init(
    slug: String,
    title: String,
    subtitle: String,
    intro: RichText?,
    link: Link?,
    media: [Media],
    chapters: [Chapter],
    tags: [String]
  ) {
    self.slug = slug
    self.title = title
    self.subtitle = subtitle
    self.intro = intro
    self.media = media
    self.link = link
    self.chapters = chapters
    self.tags = tags
  }

  /// Vrai quand les chapitres sont des chantiers nommés, dépliables un à un.
  public var hasNamedChapters: Bool {
    chapters.contains { $0.title != nil }
  }
}

extension CaseStudy {
  public struct Link: Sendable, Hashable {
    public let label: String
    public let url: URLString

    public init(label: String, url: URLString) {
      self.label = label
      self.url = url
    }
  }

  public struct Chapter: Sendable, Hashable, Identifiable {
    public var id: String { slug }

    public let slug: String
    public let title: String?
    public let subtitle: String?
    public let panels: [Panel]

    public init(slug: String, title: String?, subtitle: String?, panels: [Panel]) {
      self.slug = slug
      self.title = title
      self.subtitle = subtitle
      self.panels = panels
    }

    public func panel(_ kind: Panel.Kind) -> Panel? {
      panels.first { $0.kind == kind }
    }
  }

  public struct Panel: Sendable, Hashable, Identifiable {
    public enum Kind: String, Sendable, Hashable, CaseIterable {
      case problem, decision, result
    }

    public var id: Kind { kind }

    public let kind: Kind
    /// L'intitulé vient de la source : « Décision » ici, « Décisions et
    /// réalisations » là. C'est du contenu, pas une constante d'interface.
    public let heading: String
    public let blocks: [Block]

    public init(kind: Kind, heading: String, blocks: [Block]) {
      self.kind = kind
      self.heading = heading
      self.blocks = blocks
    }

    /// Les puces techniques, quand le panneau en porte.
    public var tags: [String] {
      blocks.compactMap { if case .tags(let items) = $0 { items } else { nil } }.flatMap(\.self)
    }

    /// Le corps rédigé, listes aplaties : dans une colonne, une liste et une
    /// suite de paragraphes se lisent pareil.
    public var prose: [RichText] {
      blocks.flatMap { block -> [RichText] in
        switch block {
        case .paragraph(let text): [text]
        case .list(let items): items
        case .tags: []
        }
      }
    }
  }

  public enum Block: Sendable, Hashable {
    case paragraph(RichText)
    case list([RichText])
    case tags([String])
  }
}
