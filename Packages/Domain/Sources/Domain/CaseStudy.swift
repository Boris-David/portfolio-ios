/// A project told: the problem, the decision, the result.
///
/// One type for both of the portfolio's layouts. What separates them is not a
/// technical property but a **property of the narrative**: a chapter with a
/// title is a piece of work that can be named and unfolded; an untitled chapter
/// is the single body of one story.
///
/// Counting the chapters would have worked today and broken on the first story
/// with two untitled chapters.
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

  /// True when the chapters are named pieces of work, each one unfoldable.
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
    /// The heading comes from the source: "Decision" here, "Decisions and
    /// deliveries" there. It is content, not an interface constant.
    public let heading: String
    public let blocks: [Block]

    public init(kind: Kind, heading: String, blocks: [Block]) {
      self.kind = kind
      self.heading = heading
      self.blocks = blocks
    }

    /// The technical chips, when the panel carries any.
    public var tags: [String] {
      blocks.compactMap { if case .tags(let items) = $0 { items } else { nil } }.flatMap(\.self)
    }

    /// The written body, lists flattened: in a single column, a list and a run
    /// of paragraphs read the same.
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
