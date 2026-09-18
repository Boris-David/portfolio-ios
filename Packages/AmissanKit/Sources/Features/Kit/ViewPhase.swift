import Foundation

/// L'état d'un écran, en quatre cas et pas un de plus.
///
/// ## Pourquoi `initial` **et** `loading` sont distincts
///
/// C'est la distinction qui fait tout le travail, et celle qu'on supprime en
/// premier quand on n'y réfléchit pas.
///
/// - `initial` : l'écran vient d'apparaître, **rien n'a encore été demandé**. Il
///   ne montre rien du tout ;
/// - `loading` : une demande est en vol. Il montre un squelette.
///
/// Les confondre produit un clignotement à chaque navigation : l'écran affiche
/// un squelette pendant la fraction de seconde qui précède le premier appel,
/// alors qu'il n'a encore rien à attendre. Sur un appareil rapide ça se voit
/// comme un sursaut ; sur un appareil lent, comme un défaut.
///
/// ## Pourquoi le rafraîchissement n'est **pas** un cinquième cas
///
/// « En train de se rafraîchir » est **orthogonal** à la phase : on rafraîchit
/// depuis `loaded` comme depuis `failed`. En faire un cas produirait des
/// combinaisons impossibles à nommer — `refreshingAfterFailure` ? — et
/// obligerait chaque `switch` à les traiter.
///
/// C'est donc un booléen porté par le store, à côté de la phase. Le geste « tirer
/// pour rafraîchir » en a besoin de toute façon : il doit savoir quand relâcher
/// son indicateur, et ça ne dépend pas de ce qu'il y a à l'écran.
public enum ViewPhase<Value: Sendable>: Sendable {
  /// L'écran vient d'apparaître. Rien n'a été demandé, rien ne s'affiche.
  case initial
  /// Une demande est en vol, et il n'y a rien à montrer en attendant.
  case loading
  /// Il y a quelque chose à montrer.
  case loaded(Value)
  /// Il n'y a rien à montrer, et on sait pourquoi.
  case failed(PhaseFailure)
}

public extension ViewPhase {
  var value: Value? {
    if case .loaded(let value) = self { value } else { nil }
  }

  var isLoaded: Bool { value != nil }

  /// Vrai tant que l'écran n'a rien à montrer — pour décider d'un squelette.
  var isPending: Bool {
    switch self {
    case .initial, .loading: true
    case .loaded, .failed: false
    }
  }
}

extension ViewPhase: Equatable where Value: Equatable {}

/// Un échec, **déjà traduit pour l'écran**.
///
/// Une vue ne reçoit jamais une `Error`. Elle reçoit un titre, une phrase et un
/// symbole, parce que décider comment une erreur se dit est un travail de
/// présentation — et parce qu'une vue qui doit faire un `switch` sur des cas
/// d'erreur du domaine est une vue qui connaît le domaine.
///
/// Le message dit **ce qui s'est passé et quoi faire**. Pas d'excuse, pas de
/// « une erreur est survenue » — qui n'apprend rien à personne.
public struct PhaseFailure: Sendable, Equatable {
  public let title: String
  public let message: String
  public let symbol: String
  /// Faux quand réessayer ne changerait rien — un contenu mal formé, par
  /// exemple. Proposer « Réessayer » dans ce cas, c'est mentir.
  public let isRetryable: Bool

  public init(title: String, message: String, symbol: String, isRetryable: Bool) {
    self.title = title
    self.message = message
    self.symbol = symbol
    self.isRetryable = isRetryable
  }
}
