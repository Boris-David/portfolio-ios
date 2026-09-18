import Data
import Domain
import Foundation
import Networking
import Persistence

/// Tout ce dont l'application a besoin pour fonctionner, en une valeur.
///
/// ## Pourquoi pas un conteneur d'injection
///
/// Un conteneur — enregistrement de types, résolution par clé — apporte deux
/// choses : la résolution paresseuse et l'enregistrement dispersé. Aucune des
/// deux n'est un avantage ici :
///
/// - **paresseuse** : trois objets, construits en microsecondes. Rien à gagner ;
/// - **dispersé** : c'est précisément ce qu'on ne veut pas. Un enregistrement
///   éparpillé fait qu'on ne sait plus, en lisant, ce qui répond à quoi — et
///   une résolution manquante ne se découvre qu'à l'exécution.
///
/// Une structure de trois champs, construite au lancement, offre l'inverse : le
/// graphe entier se lit en dix lignes, et **le compilateur** garantit qu'il est
/// complet.
public struct AppEnvironment: Sendable {
  public let portfolio: any PortfolioReading
  public let resume: any ResumeReading
  public let language: Language

  public init(portfolio: any PortfolioReading, resume: any ResumeReading, language: Language) {
    self.portfolio = portfolio
    self.resume = resume
    self.language = language
  }

  /// Le montage réel : réseau, cache disque, graine embarquée.
  public static func live(
    endpoints: Endpoints = .production,
    language: Language = .preferred()
  ) -> AppEnvironment {
    let client = URLSessionHTTPClient(session: URLSessionHTTPClient.makeSession())
    let store = FileStore()

    return AppEnvironment(
      portfolio: PortfolioRepository(
        client: client,
        store: store,
        seed: BundledSeed(),
        endpoints: endpoints
      ),
      resume: ResumeRepository(client: client, store: store, endpoints: endpoints),
      language: language
    )
  }
}

public extension Language {
  /// La langue de l'appareil, si la source la sert ; le français sinon.
  ///
  /// `preferredLanguages` et non `Locale.current.language` : le premier respecte
  /// l'ordre de **préférence** de l'utilisateur, le second ne rend que la
  /// première langue que l'application déclare supporter — ce qui reviendrait à
  /// demander au système de choisir ce qu'on essaie justement de décider.
  static func preferred() -> Language {
    for identifier in Foundation.Locale.preferredLanguages {
      let code = Foundation.Locale(identifier: identifier).language.languageCode?.identifier
      if let code, let language = Language(rawValue: code) { return language }
    }
    return .fallback
  }
}
