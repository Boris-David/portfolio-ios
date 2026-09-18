struct BackgroundDTO: Decodable {
  struct Education: Decodable {
    let slug: String
    let degree: String
    let school: String
    let detail: String?
    let startYear: Int
    let endYear: Int
  }

  struct Certification: Decodable {
    let slug: String
    let name: String
    let issuer: String
    let awardedOn: String
    let verifyUrl: String?
  }

  struct OpenProject: Decodable {
    let slug: String
    let name: String
    let description: [SpanDTO]
    let sourceUrl: String?
  }

  let education: [Education]
  let certifications: [Certification]
  let openProjects: [OpenProject]
}
