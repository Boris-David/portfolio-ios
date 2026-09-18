import AppComposition
import SwiftUI

/// Le point d'entrée.
///
/// Volontairement minuscule : douze lignes. Tout ce qui pourrait y vivre —
/// construction des dépendances, choix de la langue, composition des écrans —
/// vit dans `AppComposition`, donc dans un module **testable** et compilable
/// sans simulateur.
///
/// Un `@main` qui grossit est un `@main` qu'on ne peut plus tester : rien de ce
/// qu'il contient n'est atteignable autrement qu'en lançant l'application.
@main
struct AmissanApp: App {
  var body: some Scene {
    WindowGroup {
      AppRoot()
    }
  }
}
