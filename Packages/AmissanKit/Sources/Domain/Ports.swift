import Foundation

/// Les langues servies.
///
/// Comment on en choisit une se décide dans `LanguagePreference` et nulle part
/// ailleurs — il n'y a volontairement **pas** de `Language.fallback` ici. Une
/// constante de repli sur le type se serait retrouvée employée à deux endroits
/// avec deux règles différentes, ce qui est exactement ce qu'on veut éviter.
public enum Language: String, Sendable, Hashable, CaseIterable {
  case french = "fr"
  case english = "en"
}

/// D'où vient le contenu qu'on affiche.
///
/// Ce n'est pas une donnée de journalisation : c'est de l'**information pour le
/// lecteur**. Une application hors ligne qui n'avoue pas qu'elle est hors ligne
/// affiche du vieux contenu avec l'aplomb du neuf, et c'est exactement ce qu'on
/// ne veut pas quand un recruteur regarde par-dessus l'épaule.
public enum ContentOrigin: Sendable, Hashable {
  /// Fraîchement obtenu de la source.
  case network
  /// Relu du disque, avec la date de son enregistrement.
  case cache(storedAt: Date)
  /// La graine embarquée dans l'application — le tout premier lancement, sans
  /// réseau. Elle est **produite à la construction depuis la source**, jamais
  /// écrite à la main : ce serait une seconde vérité.
  case bundledSeed(builtAt: Date)
}

/// Le contenu, son empreinte, et ce qu'on sait de sa fraîcheur.
public struct PortfolioSnapshot: Sendable, Hashable {
  public let portfolio: Portfolio
  /// L'empreinte scellée par la source. Deux instantanés de même empreinte
  /// portent le même contenu, quelle que soit leur provenance.
  public let contentVersion: String
  public let origin: ContentOrigin
  /// Non nul quand on affiche un contenu local **parce que** le rafraîchissement
  /// a échoué. La distinction compte : « je n'ai pas encore essayé » et « j'ai
  /// essayé et je n'ai pas pu » ne se disent pas pareil à l'écran.
  public let refreshFailure: ContentUnavailable?

  public init(
    portfolio: Portfolio,
    contentVersion: String,
    origin: ContentOrigin,
    refreshFailure: ContentUnavailable? = nil
  ) {
    self.portfolio = portfolio
    self.contentVersion = contentVersion
    self.origin = origin
    self.refreshFailure = refreshFailure
  }

  /// Vrai quand ce qui est affiché ne vient pas d'être obtenu de la source.
  public var isStale: Bool {
    if case .network = origin { false } else { true }
  }
}

/// Pourquoi le contenu n'a pas pu être obtenu.
///
/// Trois cas, et pas un de plus — parce que chacun appelle une phrase
/// différente à l'écran, et qu'un quatrième cas qu'on ne saurait pas formuler
/// n'aurait aucune raison d'exister.
public enum ContentUnavailable: Error, Sendable, Hashable {
  /// Pas de réseau, ou la source ne répond pas.
  case unreachable
  /// La source a répondu, mais pas ce qu'on attendait. Le chemin du champ
  /// fautif est porté jusqu'ici : un « contenu invalide » sans lieu n'aide
  /// personne.
  case malformed(path: String, reason: String)
  /// Rien en réseau, rien en cache, pas même la graine. L'application ne peut
  /// rien afficher — le seul cas qui justifie un écran d'erreur plein.
  case nothingAvailable
}

// ─────────────────────────────────────────────────────────────────────────────
// Les ports
//
// Ce sont les seuls contrats que les fonctionnalités connaissent. Elles ne
// savent pas qu'il existe un réseau, un cache ou un bundle — et le compilateur
// le leur interdit, puisque `Networking`, `Persistence` et `Data` ne font pas
// partie de leurs dépendances.
// ─────────────────────────────────────────────────────────────────────────────

/// Quand consulter la source, et quand se contenter de ce qu'on a.
///
/// ## La règle, et pourquoi elle a changé
///
/// La première version servait **le cache d'abord**, puis le réseau : deux
/// instantanés à chaque ouverture, et un écran qui se reconstruisait. C'était
/// rapide, et c'était malhonnête — on affichait du contenu daté avec l'aplomb du
/// neuf, le temps que le réseau réponde.
///
/// La règle retenue est l'inverse, et elle tient en une phrase : **ce qu'on
/// affiche est ce que la source dit, maintenant.** Le local ne sert plus à
/// afficher *vite*, il sert à afficher *quand même* — coupure réseau, délai
/// dépassé, mode avion.
public enum FreshnessPolicy: Sendable, Hashable {
  /// Le réseau d'abord ; le local **seulement** s'il échoue. Le défaut.
  case networkFirst

  /// Le local d'abord s'il existe et n'a pas dépassé son âge ; le réseau sinon.
  ///
  /// Réservé aux appels dont le contenu ne bouge quasiment jamais. Employé par
  /// exception, jamais par confort : chaque usage se justifie, parce que chaque
  /// usage est une occasion d'afficher quelque chose de faux.
  case cacheFirst(maxAge: Duration)
}

public protocol PortfolioReading: Sendable {
  /// Le contenu, selon la politique demandée.
  ///
  /// Rend **un** instantané. Ce n'était pas le cas avant : la version précédente
  /// rendait un flux, parce qu'elle servait le cache puis le réseau. Avec
  /// « réseau d'abord », il n'y a plus qu'une réponse à donner — et une méthode
  /// qui rend une valeur se lit, se teste et se compose mieux qu'un flux dont on
  /// n'utilise qu'un élément.
  ///
  /// Ne lève **que** si rien n'est disponible, ni en réseau ni en local. Un échec
  /// réseau avec un cache utilisable n'est pas une erreur : c'est un instantané
  /// qui le dit dans `refreshFailure`.
  func portfolio(
    in language: Language,
    policy: FreshnessPolicy
  ) async throws -> PortfolioSnapshot
}

/// Le CV en PDF, produit par l'API et servi tel quel (ADR 0004).
public protocol ResumeReading: Sendable {
  /// Le document, écrit sur disque et prêt à être ouvert ou partagé.
  func resume(in language: Language) async throws -> ResumeDocument
}

/// Un CV téléchargé.
///
/// Il porte une **URL de fichier** et non ses octets. Deux raisons, et la
/// seconde est la bonne :
///
///   - `PDFView` et la feuille de partage lisent une URL sans charger le
///     document entier en mémoire ;
///   - un fichier a un **nom**, et c'est ce nom que verra le destinataire du
///     partage. Un `Data` anonyme partirait sous un nom inventé par le système.
public struct ResumeDocument: Sendable, Hashable {
  public let fileURL: URL
  /// Le nom lu dans l'en-tête `Content-Disposition` de la réponse, jamais
  /// déduit de l'URL : c'est la source qui décide comment son document
  /// s'appelle.
  public let fileName: String
  /// L'`ETag` de la réponse — ce qui rend le rechargement gratuit au retour.
  public let entityTag: String?
  public let origin: ContentOrigin

  public init(fileURL: URL, fileName: String, entityTag: String?, origin: ContentOrigin) {
    self.fileURL = fileURL
    self.fileName = fileName
    self.entityTag = entityTag
    self.origin = origin
  }
}
