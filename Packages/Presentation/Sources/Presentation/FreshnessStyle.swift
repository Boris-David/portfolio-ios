import Domain
import Foundation

/// How old the content is, said in one short sentence.
public struct FreshnessStyle: Sendable {
  private let locale: Locale

  public init(language: Language) {
    self.locale = Locale(identifier: language.rawValue)
  }

  public func describe(_ origin: ContentOrigin, now: Date = Date()) -> String? {
    switch origin {
    case .network:
      // Nothing to say: the content is the source's. A permanent "up to date"
      // banner is a banner people stop reading, and the day it says something
      // else, nobody sees it.
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
