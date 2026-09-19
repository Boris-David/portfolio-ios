/// A publishable figure, and only a publishable one.
public struct Metric: Sendable, Hashable, Identifiable {
  public let id: String
  /// The value exactly as it is written: "~5", "6", "> 99.8".
  public let value: String
  /// "M", "years", "%" — absent when the number stands alone.
  public let unit: String?
  /// Non-nil when the figure should count up as it reaches the screen. That is
  /// an editorial decision taken at the source, not an inference from the shape
  /// of the number: "~5" could be counted, and we choose not to.
  public let countTo: Int?
  public let caption: String

  public init(id: String, value: String, unit: String?, countTo: Int?, caption: String) {
    self.id = id
    self.value = value
    self.unit = unit
    self.countTo = countTo
    self.caption = caption
  }
}
