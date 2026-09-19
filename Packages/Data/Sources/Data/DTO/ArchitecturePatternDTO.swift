struct ArchitecturePatternDTO: Decodable {
  /// Kept as a `String` here, and turned into an enum case at the crossing. A
  /// DTO describes what arrives; deciding that `"mvvm"` is a value the app knows
  /// is the mapper's job, and refusing it is the mapper's job too.
  let id: String
  let name: String
  let separates: String
  let buys: [SpanDTO]
  let costs: [SpanDTO]
  let chooseWhen: [SpanDTO]
  let breaksWhen: [SpanDTO]
}
