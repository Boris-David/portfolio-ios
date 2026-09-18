import Foundation
import Testing
@testable import Networking

/// Le nom du fichier annoncé par le serveur.
///
/// C'est **le** détail qui décide du nom que verra le destinataire d'un partage.
/// Le site l'a appris à ses dépens : servi sur `/v1/cv/fr.pdf`, le CV arrivait
/// sous le nom « fr ».
struct ContentDispositionTests {
  private func headers(_ value: String) -> HTTPHeaders {
    HTTPHeaders(["Content-Disposition": value])
  }

  @Test("lit la forme entre guillemets")
  func quoted() {
    let name = ContentDisposition.fileName(in: headers(#"inline; filename="amissan.ag-cv-fr.pdf""#))
    #expect(name == "amissan.ag-cv-fr.pdf")
  }

  @Test("lit la forme sans guillemets")
  func bare() {
    #expect(ContentDisposition.fileName(in: headers("attachment; filename=cv.pdf")) == "cv.pdf")
  }

  @Test("lit la forme étendue, pourcent-décodée")
  func extended() {
    let name = ContentDisposition.fileName(
      in: headers("attachment; filename*=UTF-8''curriculum%20vit%C3%A6.pdf")
    )
    #expect(name == "curriculum vitæ.pdf")
  }

  /// `filename*` est la forme précise ; `filename` n'est qu'un repli pour les
  /// clients anciens. Quand les deux sont là, la précise gagne.
  @Test("préfère la forme étendue quand les deux sont présentes")
  func extendedWins() {
    let name = ContentDisposition.fileName(
      in: headers(#"attachment; filename="repli.pdf"; filename*=UTF-8''precis.pdf"#)
    )
    #expect(name == "precis.pdf")
  }

  @Test("est insensible à la casse de l'en-tête")
  func caseInsensitiveHeader() {
    let name = ContentDisposition.fileName(in: HTTPHeaders(["content-disposition": "inline; filename=x.pdf"]))
    #expect(name == "x.pdf")
  }

  @Test("rend nil quand l'en-tête est absent")
  func absent() {
    #expect(ContentDisposition.fileName(in: HTTPHeaders([:])) == nil)
  }

  /// ⚠️ Un nom venu du réseau est une **entrée non fiable**. Un serveur
  /// malveillant qui annoncerait un chemin écrirait hors du bac à sable si on le
  /// recopiait tel quel.
  @Test("refuse tout ce qui ressemble à un chemin", arguments: [
    #"attachment; filename="../../secrets.plist""#,
    #"attachment; filename="/etc/passwd""#,
    #"attachment; filename="..""#,
    #"attachment; filename=".""#,
  ])
  func refusesTraversal(_ header: String) {
    let name = ContentDisposition.fileName(in: headers(header))
    #expect(name == nil || !(name ?? "").contains("/"))
    #expect(name != ".." && name != ".")
  }
}

struct HTTPHeadersTests {
  /// `URLSession` rend `Content-Disposition` sur certains serveurs et
  /// `content-disposition` sur d'autres. Un dictionnaire ordinaire s'y ferait
  /// prendre un jour, sans que rien n'ait changé chez nous.
  @Test("lit un en-tête quelle que soit la casse")
  func caseInsensitive() {
    let headers = HTTPHeaders(["ETag": "\"abc\"", "content-type": "application/pdf"])
    #expect(headers["etag"] == "\"abc\"")
    #expect(headers["Content-Type"] == "application/pdf")
    #expect(headers.entityTag == "\"abc\"")
  }
}

struct HTTPRequestTests {
  private let url = URL(string: "https://api.amissan.dev/v1/cv/amissan.ag-cv-fr.pdf")!

  @Test("ajoute If-None-Match quand une empreinte est connue")
  func revalidates() {
    let request = HTTPRequest(url: url).revalidating(entityTag: "\"abc\"")
    #expect(request.headers["If-None-Match"] == "\"abc\"")
  }

  /// Envoyer `If-None-Match:` vide obtiendrait un `200` complet, donc l'inverse
  /// de ce qu'on cherche.
  @Test("n'ajoute rien quand l'empreinte manque", arguments: [nil, ""])
  func skipsEmptyTag(_ tag: String?) {
    #expect(HTTPRequest(url: url).revalidating(entityTag: tag).headers.isEmpty)
  }
}
