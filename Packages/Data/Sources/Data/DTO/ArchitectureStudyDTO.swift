struct ArchitectureStudyDTO: Decodable {
  let verifiedOn: String
  let intro: [SpanDTO]
  let patterns: [ArchitecturePatternDTO]
  let projects: [ProjectArchitectureDTO]
}
