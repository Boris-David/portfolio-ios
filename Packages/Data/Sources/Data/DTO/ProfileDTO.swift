struct ProfileDTO: Decodable {
  struct Name: Decodable {
    let display: String
    let formal: String
  }

  struct Showcase: Decodable {
    let description: String
    let media: MediaDTO
    let caseStudy: String?
  }

  struct Personality: Decodable {
    struct Highlight: Decodable {
      let title: String
      let detail: String
    }

    struct Interest: Decodable {
      let id: String
      let label: String
    }

    let highlight: Highlight
    let summary: [[SpanDTO]]
    let interests: [Interest]
  }

  struct Contact: Decodable {
    let email: String
    let title: String
    let body: String
    let links: [LinkDTO]
  }

  struct Footer: Decodable {
    let role: String
    let location: String
  }

  let name: Name
  let headline: String
  let availability: String
  let location: String
  let languages: String
  let summary: [[SpanDTO]]
  let showcase: Showcase
  let personality: Personality
  let contact: Contact
  let footer: Footer
}
