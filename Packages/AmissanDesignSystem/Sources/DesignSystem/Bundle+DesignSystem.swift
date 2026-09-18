import Foundation

public extension Bundle {
  /// Le bundle de ressources du design system — animations, actifs.
  ///
  /// `Bundle.module` est **interne** à chaque cible : depuis une
  /// fonctionnalité, il désignerait le bundle de cette fonctionnalité, pas
  /// celui-ci. L'exposer explicitement évite l'erreur silencieuse « ressource
  /// introuvable » qu'on met une heure à diagnostiquer.
  static let designSystem = Bundle.module
}
