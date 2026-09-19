struct ExperienceDTO: Decodable {
  let slug: String
  let role: String
  let organisation: String
  let location: String
  let start: String
  let end: String?
  let roles: [String]
  let highlights: [[SpanDTO]]
  let stack: [String]
}
