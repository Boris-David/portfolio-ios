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
    let blocks: [ProseBlockDTO]
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
