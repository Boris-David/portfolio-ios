import Foundation

/// Le nom de fichier annoncé par le serveur.
///
/// Il y a deux façons de l'écrire, et il faut savoir lire les deux :
///
/// ```
/// Content-Disposition: inline; filename="amissan.ag-cv-fr.pdf"
/// Content-Disposition: attachment; filename*=UTF-8''amissan.ag-cv-fr.pdf
/// ```
///
/// La seconde (RFC 5987) existe parce que la première ne sait pas porter de
/// caractères non ASCII. Quand les deux sont présentes, **`filename*` gagne** :
/// c'est la forme précise, l'autre n'étant qu'un repli pour les clients anciens.
///
/// Pourquoi ne pas simplement prendre le dernier segment de l'URL ? Parce que
/// c'est la **source** qui décide comment son document s'appelle, et qu'elle
/// peut servir `/v1/cv/fr.pdf` en le nommant `amissan.ag-cv-fr.pdf`. Le web l'a
/// appris à ses dépens : Safari sur iOS ignore cet en-tête et nomme le partage
/// d'après l'URL — le CV arrivait sous le nom « fr ».
public enum ContentDisposition {
  public static func fileName(in headers: HTTPHeaders) -> String? {
    guard let raw = headers["Content-Disposition"] else { return nil }
    return extended(from: raw) ?? quoted(from: raw) ?? bare(from: raw)
  }

  /// `filename*=UTF-8''nom%20encodé.pdf`
  private static func extended(from raw: String) -> String? {
    guard let range = raw.range(of: "filename*=", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != ";" }
    // `charset'language'valeur` — on ignore la langue, qui ne sert à rien ici.
    let parts = value.split(separator: "'", maxSplits: 2, omittingEmptySubsequences: false)
    guard parts.count == 3 else { return nil }
    return sanitised(String(parts[2]).removingPercentEncoding ?? String(parts[2]))
  }

  /// `filename="nom.pdf"`
  private static func quoted(from raw: String) -> String? {
    guard let range = raw.range(of: "filename=\"", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != "\"" }
    return sanitised(String(value))
  }

  /// `filename=nom.pdf` — sans guillemets, toléré par la norme.
  private static func bare(from raw: String) -> String? {
    guard let range = raw.range(of: "filename=", options: .caseInsensitive) else { return nil }
    let value = raw[range.upperBound...].prefix { $0 != ";" }
    return sanitised(String(value).trimmingCharacters(in: .whitespaces))
  }

  /// Un nom venu du réseau est une **entrée non fiable**.
  ///
  /// Un serveur qui annoncerait `../../Library/Preferences/truc.plist` écrirait
  /// hors du bac à sable si on le recopiait tel quel. On ne garde que le dernier
  /// composant, et on refuse ce qui ne ressemble pas à un nom de fichier.
  private static func sanitised(_ candidate: String) -> String? {
    let name = (candidate as NSString).lastPathComponent
    guard !name.isEmpty, name != ".", name != ".." else { return nil }
    guard !name.contains("/"), !name.contains("\0") else { return nil }
    return name
  }
}
