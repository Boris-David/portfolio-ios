struct ProfileDTO: Decodable {
  struct Name: Decodable {
    let display: String
    let full: String
  }

  struct Showcase: Decodable {
    let media: MediaDTO
    let caseStudy: String?
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
  let remote: String
  let languages: String
  let summary: [[SpanDTO]]
  let showcase: Showcase
  let contact: Contact
  let footer: Footer
}
