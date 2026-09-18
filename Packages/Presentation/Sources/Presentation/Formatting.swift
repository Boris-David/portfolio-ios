import Domain
import Foundation

/// Les dates lisibles, **dérivées** — jamais écrites à la main.
///
/// Le domaine porte `YearMonth(2023, 5)`. L'écran affiche « mai 2023 →
/// aujourd'hui ». Deux façons de franchir cet écart :
///
///   - une table de mois par langue. Écartée : douze entrées × deux langues à
///     tenir, et une faute d'abréviation qui ne se voit qu'en production ;
///   - **`DateFormatter`**, qui connaît déjà toutes les langues. Retenue.
///
/// Un seul détail ne s'obtient pas directement : le **point d'abréviation**. Le
/// français le porte déjà (« janv. »), l'anglais non (« Jan »), et « mai »
/// comme « May » n'en prennent aucun puisqu'ils ne sont pas abrégés. La règle
/// est donc la même dans les deux langues : *une forme courte qui diffère de la
/// forme longue est une abréviation, et une abréviation prend un point.*
///
/// C'est **exactement** la règle du site, qui l'obtient d'`Intl`. Les deux
/// plateformes affichent donc la même chaîne — pas « à peu près la même ».
public struct DateStyle: Sendable {
  private let locale: Locale

  public init(language: Language) {
    self.locale = Locale(identifier: language.rawValue)
  }

  /// « mai 2023 », « janv. 2022 », « Oct. 2020 ». Une année seule reste l'année.
  public func short(_ value: YearMonth) -> String {
    guard let month = value.month else { return String(value.year) }
    let abbreviated = abbreviatedMonth(month)
    return "\(abbreviated) \(value.year)"
  }

  /// « novembre 2025 », « November 2025 ».
  public func long(_ value: YearMonth) -> String {
    guard let month = value.month else { return String(value.year) }
    let formatter = DateFormatter()
    formatter.locale = locale
    let name = formatter.monthSymbols[month - 1]
    return "\(name) \(value.year)"
  }

  /// « mai 2023 → aujourd'hui », « janv. 2022 → avr. 2023 ».
  ///
  /// La flèche et le mot « aujourd'hui » sont de la présentation : ils vivent
  /// ici, pas dans le domaine, qui dit seulement qu'il n'y a pas de date de fin.
  public func range(from start: YearMonth, to end: YearMonth?) -> String {
    let tail = end.map(short) ?? ongoing
    return "\(short(start)) → \(tail)"
  }

  /// « 2020 — 2021 » : deux années, cadratin encadré d'espaces.
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

/// Depuis quand un contenu date, dit en une phrase courte.
public struct FreshnessStyle: Sendable {
  private let locale: Locale

  public init(language: Language) {
    self.locale = Locale(identifier: language.rawValue)
  }

  public func describe(_ origin: ContentOrigin, now: Date = Date()) -> String? {
    switch origin {
    case .network:
      // Rien à dire : le contenu est celui de la source. Une bannière « à
      // jour » en permanence est une bannière qu'on cesse de lire, et le jour
      // où elle dit autre chose personne ne la voit.
      nil
    case .cache(let storedAt):
      "\(prefixCache) \(relative(storedAt, to: now))"
    case .bundledSeed(let builtAt):
      "\(prefixSeed) \(relative(builtAt, to: now))"
    }
  }

  private var isFrench: Bool { locale.language.languageCode?.identifier == "fr" }
  private var prefixCache: String { isFrench ? "Contenu enregistré" : "Saved content from" }
  private var prefixSeed: String { isFrench ? "Contenu embarqué," : "Bundled content," }

  private func relative(_ date: Date, to now: Date) -> String {
    var formatter = RelativeDateTimeFormatter()
    formatter.locale = locale
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: now)
  }
}
