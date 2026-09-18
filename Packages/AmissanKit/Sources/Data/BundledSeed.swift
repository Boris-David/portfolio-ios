import Domain
import Foundation

/// La graine embarquée : de quoi afficher quelque chose au tout premier
/// lancement, sans réseau.
///
/// Elle est **produite à la construction depuis l'API** — `Scripts/seed.sh` —
/// et jamais écrite à la main. Une graine rédigée serait une seconde source de
/// vérité, exactement ce que l'architecture supprime partout ailleurs.
///
/// Ce n'est pas un repli silencieux : l'écran dit qu'il affiche la graine et
/// depuis quand elle date. La différence avec le web, qui refuse tout repli, est
/// assumée : le site se **construit** sur une machine avec du réseau, alors que
/// l'application est déjà dans la main de quelqu'un qui, lui, peut être dans un
/// tunnel.
public struct BundledSeed: SeedProviding {
  /// Le bundle de ressources de ce module.
  ///
  /// `Bundle.module` est **interne** à la cible qui le déclare : il ne peut pas
  /// apparaître dans la valeur par défaut d'un initialiseur public. On l'expose
  /// donc explicitement — ce qui a l'avantage de nommer ce qu'on désigne, au
  /// lieu d'un `.module` dont personne ne sait de quel module il parle.
  public static let resources = Bundle.module

  private let bundle: Bundle
  public let builtAt: Date

  public init(bundle: Bundle = BundledSeed.resources, builtAt: Date? = nil) {
    self.bundle = bundle
    self.builtAt = builtAt ?? BundledSeed.compiledAt(bundle: bundle)
  }

  public func data(for language: Language) -> Data? {
    guard let url = bundle.url(forResource: "seed-\(language.rawValue)", withExtension: "json")
    else { return nil }
    return try? Data(contentsOf: url)
  }

  /// La date de fabrication de la graine, lue sur le fichier lui-même.
  ///
  /// Pas une constante compilée : elle serait fausse dès qu'on rejouerait une
  /// construction sans régénérer la graine, et « périmé depuis » affiché faux
  /// est pire que non affiché.
  public static func compiledAt(bundle: Bundle = BundledSeed.resources) -> Date {
    guard let url = bundle.url(forResource: "seed-fr", withExtension: "json"),
          let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
          let date = values.contentModificationDate
    else { return .distantPast }
    return date
  }
}

/// Aucune graine — pour les tests qui décrivent un premier lancement nu.
public struct EmptySeed: SeedProviding {
  public let builtAt = Date.distantPast
  public init() {}
  public func data(for language: Language) -> Data? { nil }
}
