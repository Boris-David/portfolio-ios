import Domain
/// The settings screen's labels.
///
/// ## Why a nested catalogue rather than twenty more fields on `AppChrome`
///
/// `AppChrome` is one initialiser with every string in it, which is exactly
/// what makes a missing translation impossible: the compiler counts the
/// arguments. That property is worth keeping, and it stops being worth keeping
/// at around sixty parameters — past that, a call with two arguments swapped is
/// a bug nobody spots in review.
///
/// Grouping by screen keeps both properties: the compiler still counts, and each
/// group stays small enough to read in one go. The rule is one group per screen
/// that needs more than a handful of strings.
public struct SettingsChrome: Sendable, Hashable {
  public let title: String
  public let done: String

  public let appearanceSection: String
  public let appearanceSystem: String
  public let appearanceLight: String
  public let appearanceDark: String
  public let appearanceNote: String

  public let languageSection: String
  public let languageSystem: String
  public let languageFrench: String
  public let languageEnglish: String
  public let languageNote: String

  public let backstageSection: String
  public let backstageToggle: String
  public let backstageNote: String

  public let resetSection: String
  public let reset: String
  public let resetQuestion: String
  public let resetConfirm: String
  public let resetCancel: String
  public let resetDone: String

  public let saved: String
}

public extension SettingsChrome {
  static let french = SettingsChrome(
    title: "Réglages",
    done: "Terminé",
    appearanceSection: "Apparence",
    appearanceSystem: "Système",
    appearanceLight: "Clair",
    appearanceDark: "Sombre",
    appearanceNote: "« Système » suit le réglage de l'appareil, y compris la bascule automatique au coucher du soleil.",
    languageSection: "Langue",
    languageSystem: "Système",
    languageFrench: "Français",
    languageEnglish: "English",
    languageNote: "La langue choisie vaut pour l'interface **et** pour le contenu : les deux viennent de la même valeur, donc ils ne peuvent pas se contredire.",
    backstageSection: "Coulisses",
    backstageToggle: "Annotations sur les écrans",
    backstageNote: "Chaque composant reçoit une pastille numérotée qui explique pourquoi il a été choisi, et ce qui a été écarté.",
    resetSection: "Repartir de zéro",
    reset: "Réinitialiser les réglages",
    resetQuestion: "Remettre l'apparence, la langue et les coulisses à leurs valeurs d'origine ?",
    resetConfirm: "Réinitialiser",
    resetCancel: "Annuler",
    resetDone: "Réglages réinitialisés",
    saved: "Enregistré"
  )

  static let english = SettingsChrome(
    title: "Settings",
    done: "Done",
    appearanceSection: "Appearance",
    appearanceSystem: "System",
    appearanceLight: "Light",
    appearanceDark: "Dark",
    appearanceNote: "“System” follows the device, including the automatic switch at sunset.",
    languageSection: "Language",
    languageSystem: "System",
    languageFrench: "Français",
    languageEnglish: "English",
    languageNote: "The chosen language applies to the interface **and** to the content: both come from the same value, so they cannot contradict each other.",
    backstageSection: "Backstage",
    backstageToggle: "Annotations on screens",
    backstageNote: "Every component gets a numbered pin explaining why it was chosen, and what was ruled out.",
    resetSection: "Start over",
    reset: "Reset settings",
    resetQuestion: "Put appearance, language and backstage back to their original values?",
    resetConfirm: "Reset",
    resetCancel: "Cancel",
    resetDone: "Settings reset",
    saved: "Saved"
  )

  static func `for`(_ language: Language) -> SettingsChrome {
    switch language {
    case .french: .french
    case .english: .english
    }
  }
}
