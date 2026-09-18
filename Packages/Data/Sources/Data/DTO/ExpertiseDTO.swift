struct ExpertiseDTO: Decodable {
  let id: String
  let title: String
  let body: [SpanDTO]
}
