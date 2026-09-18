import SwiftUI

/// Une note et l'endroit exact qu'elle annote.
struct BackstagePin: Equatable {
  let note: BackstageNote
  let anchor: Anchor<CGRect>

  static func == (lhs: BackstagePin, rhs: BackstagePin) -> Bool {
    lhs.note == rhs.note
  }
}

/// La collecte des annotations d'un écran.
///
/// Une **préférence** plutôt qu'un registre dans le contrôleur : une préférence
/// remonte avec l'arbre de vues, donc elle se vide toute seule quand une vue
/// disparaît. Un registre aurait demandé de désinscrire à la disparition — et
/// l'oubli d'un `onDisappear` laisse des pastilles fantômes sur un écran qu'on a
/// quitté.
struct BackstagePinsKey: PreferenceKey {
  static var defaultValue: [BackstagePin] { [] }

  static func reduce(value: inout [BackstagePin], nextValue: () -> [BackstagePin]) {
    value.append(contentsOf: nextValue())
  }
}

public extension View {
  /// Annote ce composant : en mode coulisses, il reçoit une pastille numérotée
  /// qui ouvre son explication.
  ///
  /// Hors mode coulisses, le modificateur **ne change rien** — ni mise en page,
  /// ni accessibilité, ni surface tactile. Une fonctionnalité de démonstration
  /// qui dégraderait l'application ordinaire n'aurait aucun intérêt.
  /// - Important: `transformAnchorPreference` et **non** `anchorPreference`.
  ///
  ///   `anchorPreference` **remplace** la valeur de préférence du sous-arbre par
  ///   celle qu'il produit. Une annotation posée sur un conteneur efface donc
  ///   toutes celles qu'il contient — et on ne s'en aperçoit qu'en regardant
  ///   l'écran : l'annotation du `ScrollView` de l'accueil faisait disparaître
  ///   celles du logo animé et des boutons, sans erreur ni avertissement.
  ///
  ///   `transformAnchorPreference` **ajoute** à ce que les descendants ont déjà
  ///   produit, ce qui est la sémantique qu'on veut ici.
  func backstage(_ note: BackstageNote) -> some View {
    transformAnchorPreference(key: BackstagePinsKey.self, value: .bounds) { pins, anchor in
      pins.append(BackstagePin(note: note, anchor: anchor))
    }
  }
}
