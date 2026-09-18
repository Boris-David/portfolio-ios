import Domain

/// Les libellés propres aux coulisses.
///
/// Ils vivent ici, avec le module qui les affiche, et pas dans `FeatureKit` :
/// `Backstage` est **sous** `FeatureKit` dans le graphe, et une couche ne lit
/// pas les constantes de celle qui la consomme.
enum BackstageLabels {
  static let why: Bilingual = .init(fr: "Pourquoi celui-là", en: "Why this one")
  static let rejected: Bilingual = .init(fr: "Ce qui a été écarté", en: "What was ruled out")
  static let whenToUse: Bilingual = .init(fr: "Quand l'employer", en: "When to use it")
  static let pitfall: Bilingual = .init(fr: "Le piège", en: "The trap")
  static let documentation: Bilingual = .init(fr: "Documentation Apple", en: "Apple documentation")
  static let close: Bilingual = .init(fr: "Fermer", en: "Close")
  static let hint: Bilingual = .init(
    fr: "Explique pourquoi ce composant a été choisi",
    en: "Explains why this component was chosen"
  )

  static func annotation(_ number: Int, _ component: String, _ language: Language) -> String {
    switch language {
    case .french: "Coulisses \(number) : \(component)"
    case .english: "Backstage \(number): \(component)"
    }
  }
}
