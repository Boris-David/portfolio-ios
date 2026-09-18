/// Formation, certifications et projets ouverts.
public struct Background: Sendable, Hashable {
  public let education: [Education]
  public let certifications: [Certification]
  public let openProjects: [OpenProject]

  public init(education: [Education], certifications: [Certification], openProjects: [OpenProject]) {
    self.education = education
    self.certifications = certifications
    self.openProjects = openProjects
  }
}

public struct Education: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let degree: String
  public let school: String
  /// La spécialité, quand elle dit quelque chose de plus que l'intitulé.
  public let detail: String?
  public let startYear: Int
  public let endYear: Int

  public init(slug: String, degree: String, school: String, detail: String?, startYear: Int, endYear: Int) {
    self.slug = slug
    self.degree = degree
    self.school = school
    self.detail = detail
    self.startYear = startYear
    self.endYear = endYear
  }
}

public struct Certification: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let name: String
  public let issuer: String
  public let awardedOn: YearMonth
  /// L'URL de vérification. Une certification qu'on ne peut pas vérifier vaut
  /// ce que vaut la parole de celui qui l'annonce.
  public let verifyURL: URLString?

  public init(slug: String, name: String, issuer: String, awardedOn: YearMonth, verifyURL: URLString?) {
    self.slug = slug
    self.name = name
    self.issuer = issuer
    self.awardedOn = awardedOn
    self.verifyURL = verifyURL
  }
}

public struct OpenProject: Sendable, Hashable, Identifiable {
  public var id: String { slug }

  public let slug: String
  public let name: String
  public let description: RichText
  public let sourceURL: URLString?

  public init(slug: String, name: String, description: RichText, sourceURL: URLString?) {
    self.slug = slug
    self.name = name
    self.description = description
    self.sourceURL = sourceURL
  }
}

public struct SkillGroup: Sendable, Hashable, Identifiable {
  public let id: String
  public let title: String
  public let items: [String]

  public init(id: String, title: String, items: [String]) {
    self.id = id
    self.title = title
    self.items = items
  }
}

/// Un sujet creusé — ce sur quoi il peut être interrogé au fond.
public struct ExpertiseTopic: Sendable, Hashable, Identifiable {
  public let id: String
  public let title: String
  public let body: RichText

  public init(id: String, title: String, body: RichText) {
    self.id = id
    self.title = title
    self.body = body
  }
}

/// Un chiffre publiable, et lui seul.
public struct Metric: Sendable, Hashable, Identifiable {
  public let id: String
  /// La valeur telle qu'elle s'écrit : « ~5 », « 6 », « > 99,8 ».
  public let value: String
  /// « M », « ans », « % » — absent quand le nombre se suffit.
  public let unit: String?
  /// Non nul quand le chiffre doit s'animer en arrivant à l'écran. C'est une
  /// décision éditoriale prise à la source, pas une déduction sur la forme du
  /// nombre : « ~5 » pourrait se compter, on choisit que non.
  public let countTo: Int?
  public let caption: String

  public init(id: String, value: String, unit: String?, countTo: Int?, caption: String) {
    self.id = id
    self.value = value
    self.unit = unit
    self.countTo = countTo
    self.caption = caption
  }
}
