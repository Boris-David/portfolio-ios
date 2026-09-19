/// A year, optionally narrowed to a month.
///
/// Neither `Date` nor `DateComponents`: both carry a time, a time zone and a
/// precision down to the second that a career has no use for — and a date that
/// crosses a time zone changes month. Here, "May 2023" is May 2023 everywhere on
/// the planet.
public struct YearMonth: Sendable, Hashable, Comparable {
  public let year: Int
  /// 1 to 12, or `nil` when the source gives only the year.
  public let month: Int?

  public init(year: Int, month: Int? = nil) {
    self.year = year
    self.month = month
  }

  public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
    (lhs.year, lhs.month ?? 1) < (rhs.year, rhs.month ?? 1)
  }
}
