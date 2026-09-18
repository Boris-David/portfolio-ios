import Domain

/// The interface labels, in the language **of the content on screen**.
///
/// ## Why not a string catalogue
///
/// That is the normal tool for localising an iOS app, and it has a precise
/// behaviour: it follows the **device's language**.
///
/// But here the content comes from the API. If the source did not serve the
/// device's language — because it does not have it, or because it fell back —
/// the interface would speak one language and the content another.
///
/// This is not hypothetical: it is **the defect observed on the first launch**.
/// The simulator was in English, the API served English, and the tabs read
/// "Profil · Travail · Parcours · Coulisses" above an English body. An app that
/// contradicts itself on screen is not redeemed by the quality of the rest.
///
/// Hence the choice: **the chrome follows the content**, not the device. The two
/// can no longer diverge, because they descend from the same value.
///
/// It is also exactly the website's structure, where `src/content/chrome/`
/// carries what exists only because there is an interface. The test is the same:
/// *content is what would still be true if this client did not exist.*
public struct AppChrome: Sendable, Hashable {
  public let language: Language

  // Tabs
  public let tabProfile: String
  public let tabWork: String
  public let tabJourney: String
  public let tabBackstage: String

  // Shared actions
  public let close: String
  public let retry: String
  public let share: String
  public let contactAction: String
  public let resumeAction: String
  public let loading: String

  // Profile
  public let contactTitle: String

  // Work
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

  // Journey
  public let education: String
  public let certifications: String
  public let openProjects: String
  public let skills: String
  public let verifyCertificate: String
  public let sourceCode: String

  // Résumé
  public let resumeTitle: String
  public let resumeLoading: String
  public let revalidated: String

  // States
  public let unavailableTitle: String
  public let unreadableTitle: String
  public let unreachableMessage: String
  public let nothingAvailableMessage: String
  /// Says, in the reader's language, what the source got wrong and where.
  ///
  /// The diagnosis is shown in full rather than wrapped in an apology. This is a
  /// portfolio app: somebody looking at it is better served by the actual field
  /// path than by "an error occurred".
  public func malformedMessage(path: String, reason: MalformedReason) -> String {
    language == .french
      ? "La source a répondu quelque chose d'inattendu en « \(path) » : \(describe(reason))."
      : "The source returned something unexpected at “\(path)”: \(describe(reason))."
  }

  private func describe(_ reason: MalformedReason) -> String {
    switch (reason, language) {
    case (.missingField, .french): "champ absent"
    case (.missingField, .english): "the field is missing"

    case (.unexpectedType(let expected), .french): "type inattendu, \(expected) attendu"
    case (.unexpectedType(let expected), .english): "unexpected type, expected \(expected)"

    case (.nullValue(let expected), .french): "valeur nulle, \(expected) attendu"
    case (.nullValue(let expected), .english): "null value, expected \(expected)"

    case (.unreadable(let detail), _): detail

    case (.wrongLanguage(let served, let requested), .french):
      "réponse en « \(served) » alors que « \(requested) » était demandé"
    case (.wrongLanguage(let served, let requested), .english):
      "answered in “\(served)” when “\(requested)” was requested"

    case (.unknownValue(let value), .french): "valeur « \(value) » inconnue"
    case (.unknownValue(let value), .english): "unknown value “\(value)”"

    case (.unreadableDate(let raw), .french):
      "date « \(raw) » illisible — « AAAA » ou « AAAA-MM » attendu"
    case (.unreadableDate(let raw), .english):
      "unreadable date “\(raw)” — expected “YYYY” or “YYYY-MM”"

    case (.monthOutOfRange(let raw), .french): "mois « \(raw) » hors de 01–12"
    case (.monthOutOfRange(let raw), .english): "month “\(raw)” outside 01–12"

    case (.unacceptableFileName(let name), .french): "« \(name) » n'est pas un nom de fichier acceptable"
    case (.unacceptableFileName(let name), .english): "“\(name)” is not an acceptable file name"

    case (.insecureURL(let raw), .french): "« \(raw) » n'est pas une URL https"
    case (.insecureURL(let raw), .english): "“\(raw)” is not an https URL"
    }
  }

  // Backstage
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
  /// Which of the two renderings the reader is looking at.
  ///
  /// The design system knows the **fact** — `PlatformCapabilities` — and this
  /// says it in the reader's language. A layer that cannot see the language must
  /// not write sentences; this one can.
  public func renderingSummary(supportsLiquidGlass: Bool) -> String {
    switch (supportsLiquidGlass, language) {
    case (true, .french): "iOS 26 — Liquid Glass natif"
    case (true, .english): "iOS 26 — native Liquid Glass"
    case (false, .french): "iOS 18 — repli en matériau système"
    case (false, .english): "iOS 18 — system material fallback"
    }
  }

  public let settings: String
  public let aboutLink: String
  public let copyLink: String
  public let linkCopied: String
  public let aboutTitle: String
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
    architectureIntro: "Chaque couche est un package SPM : une dépendance absente n'est pas une convention, c'est un `import` qui ne résout pas.",
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
    settings: "Réglages",
    aboutLink: "Lire la présentation",
    copyLink: "Copier le lien App Store",
    linkCopied: "Lien copié",
    aboutTitle: "À propos",
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
    architectureIntro: "Every layer is an SPM package: a missing dependency is not a convention, it is an `import` that does not resolve.",
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
    settings: "Settings",
    aboutLink: "Read the introduction",
    copyLink: "Copy the App Store link",
    linkCopied: "Link copied",
    aboutTitle: "About",
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
