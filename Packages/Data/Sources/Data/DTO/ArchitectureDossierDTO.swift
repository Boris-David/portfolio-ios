struct ArchitectureDossierDTO: Decodable {
  let verifiedOn: String
  let intro: [SpanDTO]
  let patterns: [ArchitecturePatternDTO]
  let projects: [ProjectArchitectureDTO]
}
