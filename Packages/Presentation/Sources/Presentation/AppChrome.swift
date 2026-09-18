import Domain

/// Les libellés d'interface, dans la langue **du contenu affiché**.
///
/// ## Pourquoi pas un catalogue de chaînes
///
/// C'est l'outil normal pour localiser une application iOS, et il a un
/// comportement précis : il suit la **langue de l'appareil**.
///
/// Or ici le contenu, lui, vient de l'API. Si la source ne servait pas la langue
/// de l'appareil — parce qu'elle ne la connaît pas, ou parce qu'elle s'est
/// repliée — l'interface parlerait une langue et le contenu une autre.
///
/// Ce n'est pas théorique : c'est **le défaut observé au premier lancement**.
/// Le simulateur était en anglais, l'API a servi l'anglais, et les onglets
/// affichaient « Profil · Travail · Parcours · Coulisses » au-dessus d'un texte
/// anglais. Une application qui se contredit à l'écran ne se rattrape pas par
/// la qualité du reste.
///
/// D'où le choix : **le chrome suit le contenu**, pas l'appareil. Les deux ne
/// peuvent alors plus diverger, parce qu'ils descendent de la même valeur.
///
/// C'est aussi exactement la structure du site, où `src/content/chrome/`
/// porte ce qui n'existe que parce qu'il y a une interface. Le critère est le
/// même : *est du contenu ce qui resterait vrai si ce client n'existait pas.*
public struct AppChrome: Sendable, Hashable {
  public let language: Language

  // Onglets
  public let tabProfile: String
  public let tabWork: String
  public let tabJourney: String
  public let tabBackstage: String

  // Actions communes
  public let close: String
  public let retry: String
  public let share: String
  public let contactAction: String
  public let resumeAction: String
  public let loading: String

  // Profil
  public let contactTitle: String

  // Travail
  public func chapterCount(_ count: Int) -> String {
    language == .french ? "\(count) chantiers" : "\(count) workstreams"
  }
  public let readStudy: String
  public func verifiedOn(_ date: String) -> String {
    language == .french
      ? "Identifiants App Store vérifiés le \(date)."
      : "App Store identifiers verified on \(date)."
  }
  public let openInAppStore: String

  // Parcours
  public let education: String
  public let certifications: String
  public let openProjects: String
  public let skills: String
  public let verifyCertificate: String
  public let sourceCode: String

  // CV
  public let resumeTitle: String
  public let resumeLoading: String
  public let revalidated: String

  // États
  public let unavailableTitle: String
  public let unreadableTitle: String
  public let unreachableMessage: String
  public let nothingAvailableMessage: String
  public func malformedMessage(path: String, reason: String) -> String {
    language == .french
      ? "La source a répondu quelque chose d'inattendu en « \(path) » : \(reason)."
      : "The source returned something unexpected at “\(path)”: \(reason)."
  }

  // Coulisses
  public let backstageEyebrow: String
  public let backstageTitle: String
  public let backstageIntro: String
  public let backstageToggle: String
  public let backstageShow: String
  public let backstageHide: String
  public let architecture: String
  public let architectureIntro: String
  public let challenges: String
  public let endToEnd: String
  public let dependencies: String
  public let dependenciesRule: String
  public let noDependency: String
  public let declined: String
  public let theProblem: String
  public let theSolution: String
  public let theLesson: String
  public let whySoOne: String
  public let whatWasRejected: String
  public let whenToUse: String
  public let thePitfall: String
  public let appleDocumentation: String
  public func annotationLabel(_ number: Int, _ component: String) -> String {
    language == .french
      ? "Coulisses \(number) : \(component)"
      : "Backstage \(number): \(component)"
  }
  public let routeMissingTitle: String
  public let routeMissingMessage: String
  public let annotationHint: String
  public let expanded: String
  public let collapsed: String
}

public extension AppChrome {
  static let french = AppChrome(
    language: .french,
    tabProfile: "Profil",
    tabWork: "Travail",
    tabJourney: "Parcours",
    tabBackstage: "Coulisses",
    close: "Fermer",
    retry: "Réessayer",
    share: "Partager",
    contactAction: "Me contacter",
    resumeAction: "Mon CV",
    loading: "Chargement du contenu",
    contactTitle: "Contact",
    readStudy: "Lire l'étude",
    openInAppStore: "Ouvre la fiche App Store",
    education: "Formation",
    certifications: "Certifications",
    openProjects: "Projets ouverts",
    skills: "Compétences",
    verifyCertificate: "Vérifier le certificat",
    sourceCode: "Code source",
    resumeTitle: "CV",
    resumeLoading: "Récupération du CV…",
    revalidated: "revalidé",
    unavailableTitle: "Contenu indisponible",
    unreadableTitle: "Contenu illisible",
    unreachableMessage: "La source n'a pas répondu, et rien n'est encore enregistré sur cet appareil.",
    nothingAvailableMessage: "Aucun contenu disponible hors ligne pour le moment.",
    backstageEyebrow: "Sous le capot",
    backstageTitle: "Pourquoi cette application est faite comme ça",
    backstageIntro: """
      Les décisions, ce qu'elles ont écarté, et les pièges qu'elles évitent. \
      Activez les annotations pour voir, écran par écran, quel composant fait quoi.
      """,
    backstageToggle: "Annotations sur les écrans",
    backstageShow: "Voir les coulisses",
    backstageHide: "Masquer les coulisses",
    architecture: "L'architecture",
    architectureIntro: "Chaque couche est une cible SPM : une dépendance absente n'est pas une convention, c'est un `import` qui ne compile pas.",
    challenges: "Les défis techniques",
    endToEnd: "De bout en bout",
    dependencies: "Les dépendances",
    dependenciesRule: "La règle : *une dépendance se justifie par ce qui serait pire sans elle, pas par ce qu'elle rend pratique.*",
    noDependency: "aucune dépendance",
    declined: "écartée",
    theProblem: "Le problème",
    theSolution: "La solution",
    theLesson: "Ce qu'on en retient",
    whySoOne: "Pourquoi celui-là",
    whatWasRejected: "Ce qui a été écarté",
    whenToUse: "Quand l'employer",
    thePitfall: "Le piège",
    appleDocumentation: "Documentation Apple",
    routeMissingTitle: "Contenu introuvable",
    routeMissingMessage: "Ce projet n'existe pas dans le contenu chargé.",
    annotationHint: "Explique pourquoi ce composant a été choisi",
    expanded: "déplié",
    collapsed: "replié"
  )

  static let english = AppChrome(
    language: .english,
    tabProfile: "Profile",
    tabWork: "Work",
    tabJourney: "Journey",
    tabBackstage: "Backstage",
    close: "Close",
    retry: "Try again",
    share: "Share",
    contactAction: "Get in touch",
    resumeAction: "My résumé",
    loading: "Loading content",
    contactTitle: "Contact",
    readStudy: "Read the study",
    openInAppStore: "Opens the App Store page",
    education: "Education",
    certifications: "Certifications",
    openProjects: "Open projects",
    skills: "Skills",
    verifyCertificate: "Verify certificate",
    sourceCode: "Source code",
    resumeTitle: "Résumé",
    resumeLoading: "Fetching the résumé…",
    revalidated: "revalidated",
    unavailableTitle: "Content unavailable",
    unreadableTitle: "Content unreadable",
    unreachableMessage: "The source did not respond, and nothing is stored on this device yet.",
    nothingAvailableMessage: "No content available offline right now.",
    backstageEyebrow: "Under the hood",
    backstageTitle: "Why this app is built the way it is",
    backstageIntro: """
      The decisions, what they ruled out, and the traps they avoid. Turn on \
      annotations to see, screen by screen, what each component does.
      """,
    backstageToggle: "Annotations on screens",
    backstageShow: "Show the backstage",
    backstageHide: "Hide the backstage",
    architecture: "The architecture",
    architectureIntro: "Every layer is an SPM target: a missing dependency is not a convention, it is an `import` that does not compile.",
    challenges: "Technical challenges",
    endToEnd: "End to end",
    dependencies: "Dependencies",
    dependenciesRule: "The rule: *a dependency earns its place by what would be worse without it, not by what it makes convenient.*",
    noDependency: "no dependency",
    declined: "declined",
    theProblem: "The problem",
    theSolution: "The solution",
    theLesson: "What it teaches",
    whySoOne: "Why this one",
    whatWasRejected: "What was ruled out",
    whenToUse: "When to use it",
    thePitfall: "The trap",
    appleDocumentation: "Apple documentation",
    routeMissingTitle: "Content not found",
    routeMissingMessage: "This project is not in the loaded content.",
    annotationHint: "Explains why this component was chosen",
    expanded: "expanded",
    collapsed: "collapsed"
  )

  static func `for`(_ language: Language) -> AppChrome {
    switch language {
    case .french: .french
    case .english: .english
    }
  }
}
