struct DeepDiveDTO: Decodable {
  struct Section: Decodable {
    let slug: String
    let heading: String
    let blocks: [ProseBlockDTO]
  }

  struct Evidence: Decodable {
    let caseStudy: String
    let chapter: String
  }

  /// The `ExpertiseDTO.id` this dive belongs to.
  let expertise: String
  let lede: [SpanDTO]
  let sections: [Section]
  let evidence: Evidence?
}
