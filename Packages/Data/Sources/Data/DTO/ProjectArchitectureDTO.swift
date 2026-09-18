struct ProjectArchitectureDTO: Decodable {
  let id: String
  let name: String
  let context: String
  /// A **reference** to one of the patterns above, by identifier. The source
  /// writes the trade-offs once and points at them; the mapper is where that
  /// pointer is followed.
  let pattern: String
  let stack: [String]
  let evidence: [ArchitectureEvidenceDTO]
  let reading: [SpanDTO]
}
