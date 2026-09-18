import Foundation

/// Le port du transport.
///
/// ## Pourquoi pas Alamofire
///
/// Ce n'est pas une position de principe contre la bibliothèque, qui est très
/// bonne. C'est que **ce qu'elle apporte, on ne s'en sert pas** :
///
/// - *le chaînage de requêtes et la validation* — ce protocole fait deux
///   méthodes, et la validation tient en une comparaison de statut ;
/// - *l'`async/await`* — `URLSession` le fournit nativement depuis iOS 15 ;
/// - *les intercepteurs et le rejeu* — ils vivent dans la couche `Data`, avec
///   la politique de fraîcheur, parce que réessayer est une décision métier
///   (« combien de temps un recruteur attend-il ? ») et pas une décision de
///   transport ;
/// - *le multipart et l'upload* — l'application ne fait que lire.
///
/// Ce qu'on paierait en revanche est réel : une dépendance de plus à auditer
/// sur un dépôt public, un binaire plus gros, une surface d'API à expliquer à
/// l'oral, et une montée de version à suivre pour du code qui n'évolue pas.
///
/// **La règle générale** : une dépendance se justifie par ce qui serait pire
/// sans elle, pas par ce qu'elle rend pratique. Ici, ce serait pire sans Lottie
/// — personne ne réécrit un moteur d'animation vectorielle. Ce n'est pas pire
/// sans Alamofire.
///
/// Et le protocole est ce qui rend ce choix **réversible** : le jour où
/// l'application aurait besoin de ce qu'Alamofire apporte, une implémentation
/// de plus suffirait, sans qu'aucune vue ne bouge.
public protocol HTTPClient: Sendable {
  /// Envoie et attend la réponse complète.
  func send(_ request: HTTPRequest) async throws(HTTPError) -> HTTPResponse

  /// Écrit le corps de la réponse **dans un fichier** plutôt qu'en mémoire.
  ///
  /// Un PDF de plusieurs mégaoctets n'a aucune raison de transiter par la
  /// mémoire vive : `PDFView` comme la feuille de partage lisent une URL. Le
  /// fichier temporaire rendu est à déplacer par l'appelant — `URLSession` le
  /// supprime dès le retour.
  func download(_ request: HTTPRequest) async throws(HTTPError) -> HTTPDownload
}

/// Le résultat d'un téléchargement : où sont les octets, et ce que le serveur
/// a dit d'eux.
public struct HTTPDownload: Sendable {
  public let status: Int
  public let headers: HTTPHeaders
  /// `nil` sur un `304` : il n'y a pas de corps, et c'est la bonne nouvelle.
  public let temporaryURL: URL?

  public init(status: Int, headers: HTTPHeaders, temporaryURL: URL?) {
    self.status = status
    self.headers = headers
    self.temporaryURL = temporaryURL
  }

  public var isSuccess: Bool { (200..<300).contains(status) }
  public var isNotModified: Bool { status == 304 }
}
