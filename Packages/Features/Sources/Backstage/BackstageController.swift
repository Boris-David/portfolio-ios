import Observation
import SwiftUI

/// L'état du mode coulisses, partagé par toute l'application.
///
/// `@Observable` plutôt qu'`ObservableObject` : SwiftUI n'observe alors que les
/// propriétés **réellement lues** par chaque vue. Avec `@Published`, activer le
/// mode aurait invalidé toute vue tenant l'objet, y compris celles qui ne
/// regardent que la note sélectionnée.
@Observable
@MainActor
public final class BackstageController {
  /// Les annotations sont-elles visibles ?
  public var isEnabled = false
  /// La note ouverte en détail, s'il y en a une.
  public var presented: BackstageNote?

  public init(isEnabled: Bool = false) {
    self.isEnabled = isEnabled
  }

  public func toggle() {
    isEnabled.toggle()
    if !isEnabled { presented = nil }
  }

  public func present(_ note: BackstageNote) {
    presented = note
  }
}

// Le contrôleur voyage par `.environment(controller)` et se lit par
// `@Environment(BackstageController.self)`.
//
// Pas par une clé `@Entry` : une clé exige une **valeur par défaut**, et
// construire un objet isolé à l'acteur principal hors de cet acteur ne compile
// pas. Le contourner par `MainActor.assumeIsolated` marcherait — en déposant un
// piège à l'exécution dans du code livré, pour un défaut que personne ne devrait
// jamais obtenir.
//
// L'injection d'objet dit mieux ce qu'on veut : ce contrôleur n'a pas de valeur
// par défaut sensée. Ou l'application l'a fourni, ou il y a un défaut de
// câblage — et il vaut mieux l'apprendre au premier lancement qu'observer un
// mode coulisses qui ne réagit à rien.
