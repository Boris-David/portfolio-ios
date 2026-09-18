import Domain
import Observation
import SwiftUI

/// Les destinations atteignables depuis un onglet.
///
/// Un `enum Hashable` et une navigation **par valeur** : la vue déclare
/// `NavigationLink(value:)`, et la racine résout. Une `NavigationLink(destination:)`
/// coupleraient chaque cellule à l'écran qu'elle ouvre — il deviendrait
/// impossible de réutiliser la cellule ailleurs, et impossible d'ouvrir cet
/// écran depuis un lien profond.
public enum Route: Hashable, Sendable {
  case caseStudy(slug: String)
  case experience(slug: String)
  case expertise(id: String)
  case allApps
}

/// Ce qui se présente par-dessus, sans quitter l'écran.
public enum Sheet: Identifiable, Hashable, Sendable {
  case resume
  case contact

  public var id: Self { self }
}

/// Le routeur d'une section.
///
/// Un par onglet, jamais un global : partager une pile entre onglets fait
/// revenir l'utilisateur sur l'écran d'un autre onglet en tapant « retour », ce
/// qui n'a aucun sens pour lui.
@Observable
@MainActor
public final class Router {
  public var path: [Route] = []
  public var sheet: Sheet?

  public init() {}

  public func push(_ route: Route) { path.append(route) }
  public func pop() { if !path.isEmpty { path.removeLast() } }
  public func popToRoot() { path.removeAll() }
  public func present(_ sheet: Sheet) { self.sheet = sheet }
}

/// Les onglets de l'application.
public enum Section: String, CaseIterable, Hashable, Sendable, Identifiable {
  case profile
  case work
  case journey
  case backstage

  public var id: String { rawValue }

  /// Le libellé vient du chrome, donc de la langue affichée — pas d'ici.
  /// Une énumération qui porterait ses propres chaînes les porterait dans une
  /// seule langue, et il faudrait s'en souvenir le jour où on en ajoute une.
  public func title(_ chrome: AppChrome) -> String {
    switch self {
    case .profile: chrome.tabProfile
    case .work: chrome.tabWork
    case .journey: chrome.tabJourney
    case .backstage: chrome.tabBackstage
    }
  }

  /// Un symbole SF, choisi pour ce qu'il **désigne** et non pour sa jolie forme.
  public var symbol: String {
    switch self {
    case .profile: "person.crop.square"
    case .work: "square.stack.3d.up"
    case .journey: "calendar"
    case .backstage: "wrench.and.screwdriver"
    }
  }
}
