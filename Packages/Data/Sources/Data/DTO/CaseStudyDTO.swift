struct CaseStudyDTO: Decodable {
  struct Chapter: Decodable {
    let slug: String
    let title: String?
    let subtitle: String?
    let panels: [Panel]
  }

  struct Panel: Decodable {
    let kind: String
    let heading: String
    let blocks: [Block]
  }

  /// A polymorphic block, discriminated by `type`.
  ///
  /// Decoded by hand rather than by a synthesised `Codable` enum: the API's
  /// shape is not the one Swift generates, and bending the model to fit the
  /// generator would be letting the tool decide the contract.
  enum Block: Decodable {
    case paragraph([SpanDTO])
    case list([[SpanDTO]])
    case tags([String])

    private enum CodingKeys: String, CodingKey {
      case type, text, items
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
      case "paragraph":
        self = .paragraph(try container.decode([SpanDTO].self, forKey: .text))
      case "list":
        self = .list(try container.decode([[SpanDTO]].self, forKey: .items))
      case "tags":
        self = .tags(try container.decode([String].self, forKey: .items))
      default:
        // An unknown type is an **error**, not a block to skip. Skipping would
        // make content disappear silently: the page would simply look a little
        // shorter, and nobody would notice.
        throw DecodingError.dataCorruptedError(
          forKey: .type,
          in: container,
          debugDescription: "unknown block type “\(type)”"
        )
      }
    }
  }

  let slug: String
  let title: String
  let subtitle: String
  let intro: [SpanDTO]?
  let link: LinkLabelDTO?
  let media: [MediaDTO]
  let chapters: [Chapter]
  let tags: [String]
}
