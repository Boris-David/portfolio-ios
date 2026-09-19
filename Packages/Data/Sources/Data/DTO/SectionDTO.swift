struct SectionDTO: Decodable {
  let id: String
  let eyebrow: String
  let title: String
  let intro: [SpanDTO]?
  let note: [SpanDTO]?
}
