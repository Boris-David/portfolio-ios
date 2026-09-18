import Domain
import Foundation

/// Readable dates, **derived** — never written by hand.
///
/// The domain carries `YearMonth(2023, 5)`. The screen shows "May 2023 → today".
/// Two ways to cross that gap:
///
///   - a table of months per language. Ruled out: twelve entries × two languages
///     to maintain, and an abbreviation mistake that only shows in production;
///   - **`DateFormatter`**, which already knows every language. Kept.
///
/// One detail does not come for free: the **abbreviation period**. French
/// already carries it ("janv."), English does not ("Jan"), and neither "mai" nor
/// "May" take one since they are not abbreviated. So the rule is the same in
/// both languages: *a short form that differs from the long form is an
/// abbreviation, and an abbreviation takes a period.*
///
/// It is **exactly** the website's rule, which gets it from `Intl`. Both
/// platforms therefore print the same string — not "roughly the same".
public struct DateStyle: Sendable {
  private let locale: Locale

  public init(language: Language) {
    self.locale = Locale(identifier: language.rawValue)
  }

  /// "May 2023", "janv. 2022", "Oct. 2020". A bare year stays the year.
  public func short(_ value: YearMonth) -> String {
    guard let month = value.month else { return String(value.year) }
    let abbreviated = abbreviatedMonth(month)
    return "\(abbreviated) \(value.year)"
  }

  /// "novembre 2025", "November 2025".
  public func long(_ value: YearMonth) -> String {
    guard let month = value.month else { return String(value.year) }
    let formatter = DateFormatter()
    formatter.locale = locale
    let name = formatter.monthSymbols[month - 1]
    return "\(name) \(value.year)"
  }

  /// "May 2023 → today", "janv. 2022 → avr. 2023".
  ///
  /// The arrow and the word "today" are presentation: they live here, not in the
  /// domain, which only says there is no end date.
  public func range(from start: YearMonth, to end: YearMonth?) -> String {
    let tail = end.map(short) ?? ongoing
    return "\(short(start)) → \(tail)"
  }

  /// "2020 — 2021": two years, an em dash with spaces around it.
  public func years(_ start: Int, _ end: Int) -> String {
    "\(start) — \(end)"
  }

  private var ongoing: String {
    locale.language.languageCode?.identifier == "fr" ? "aujourd'hui" : "today"
  }

  private func abbreviatedMonth(_ month: Int) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    let short = formatter.shortMonthSymbols[month - 1]
    let long = formatter.monthSymbols[month - 1]
    guard short != long, !short.hasSuffix(".") else { return short }
    return short + "."
  }
}
