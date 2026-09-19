struct MetricDTO: Decodable {
  let id: String
  let value: String
  let unit: String?
  let countTo: Int?
  let caption: String
}
