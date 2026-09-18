import Foundation

/// Ce qui peut mal tourner au niveau du transport, et rien d'autre.
///
/// Aucun cas ne parle du portfolio : cette couche ne sait pas ce qu'elle
/// transporte. C'est ce qui permet de la tester sans rien savoir du domaine —
/// et de la remplacer sans rouvrir une ligne ailleurs.
public enum HTTPError: Error, Sendable, Hashable {
  /// Rien n'est parti, ou rien n'est revenu : pas de réseau, hôte injoignable,
  /// délai dépassé.
  case transport(description: String)
  /// Le serveur a répondu, mais avec un statut dont on ne peut rien faire.
  case status(Int)
  /// La réponse n'est pas une réponse HTTP — cas théorique d'`URLSession`, qu'on
  /// refuse de traiter par un `as!`.
  case notHTTP
}

extension HTTPError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .transport(let description): "transport — \(description)"
    case .status(let code): "statut HTTP \(code)"
    case .notHTTP: "réponse non HTTP"
    }
  }
}
