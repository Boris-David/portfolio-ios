import Foundation

/// La charge utile de l'API, décrite telle qu'elle arrive.
///
/// Ces types vivent ici et **jamais dans `Domain`**. Une entité qui porte des
/// `CodingKeys` est une entité qui a laissé le réseau dicter sa forme : le jour
/// où l'API renomme un champ, c'est le cœur de l'application qu'on rouvre.
/// Ici, seul l'adaptateur bouge.
///
/// Ils sont `internal` : rien à l'extérieur de `Data` n'a de raison de savoir
/// qu'une réponse JSON existe.
struct PortfolioEnvelopeDTO: Decodable {
  struct Meta: Decodable {
    let locale: String
    let contentVersion: String
  }

  let meta: Meta
  let data: PortfolioDTO
}

struct PortfolioDTO: Decodable {
  let profile: ProfileDTO
  let metrics: [MetricDTO]
  let sections: [SectionDTO]
  let caseStudies: [CaseStudyDTO]
  let apps: AppCatalogueDTO
  let expertise: [ExpertiseDTO]
  let experience: [ExperienceDTO]
  let background: BackgroundDTO
  let skills: [SkillGroupDTO]
}

// ─────────────────────────────────────────────────────────────────────────────
// Texte riche
// ─────────────────────────────────────────────────────────────────────────────

struct SpanDTO: Decodable {
  let text: String
  let style: String
}

// ─────────────────────────────────────────────────────────────────────────────
// Profil
// ─────────────────────────────────────────────────────────────────────────────

struct ProfileDTO: Decodable {
  struct Name: Decodable {
    let display: String
    let full: String
  }

  struct Showcase: Decodable {
    let media: MediaDTO
    let caseStudy: String?
  }

  struct Contact: Decodable {
    let email: String
    let title: String
    let body: String
    let links: [LinkDTO]
  }

  struct Footer: Decodable {
    let role: String
    let location: String
  }

  let name: Name
  let headline: String
  let availability: String
  let location: String
  let remote: String
  let languages: String
  let summary: [[SpanDTO]]
  let showcase: Showcase
  let contact: Contact
  let footer: Footer
}

struct LinkDTO: Decodable {
  let id: String
  let label: String
  let url: String
}

struct MediaDTO: Decodable {
  let id: String
  let alt: String
  let caption: String
}

// ─────────────────────────────────────────────────────────────────────────────
// Chiffres et sections
// ─────────────────────────────────────────────────────────────────────────────

struct MetricDTO: Decodable {
  let id: String
  let value: String
  let unit: String?
  let countTo: Int?
  let caption: String
}

struct SectionDTO: Decodable {
  let id: String
  let eyebrow: String
  let title: String
  let intro: [SpanDTO]?
  let note: [SpanDTO]?
}

// ─────────────────────────────────────────────────────────────────────────────
// Études de cas
// ─────────────────────────────────────────────────────────────────────────────

struct CaseStudyDTO: Decodable {
  struct Chapter: Decodable {
    let slug: String
    let title: String?
    let subtitle: String?
    let panels: [Panel]
  }

  struct Panel: Decodable {
    let kind: String
    let heading: String
    let blocks: [Block]
  }

  /// Un bloc polymorphe, discriminé par `type`.
  ///
  /// Décodé à la main plutôt que par un `enum` `Codable` synthétisé : la forme
  /// de l'API n'est pas celle que Swift génère, et tordre le modèle pour
  /// coller au générateur reviendrait à laisser l'outil décider du contrat.
  enum Block: Decodable {
    case paragraph([SpanDTO])
    case list([[SpanDTO]])
    case tags([String])

    private enum CodingKeys: String, CodingKey {
      case type, text, items
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
      case "paragraph":
        self = .paragraph(try container.decode([SpanDTO].self, forKey: .text))
      case "list":
        self = .list(try container.decode([[SpanDTO]].self, forKey: .items))
      case "tags":
        self = .tags(try container.decode([String].self, forKey: .items))
      default:
        // Un type inconnu est une **erreur**, pas un bloc qu'on saute. Sauter
        // ferait disparaître du contenu sans bruit : la page paraîtrait juste
        // un peu plus courte, et personne ne s'en apercevrait.
        throw DecodingError.dataCorruptedError(
          forKey: .type,
          in: container,
          debugDescription: "bloc de type « \(type) » inconnu"
        )
      }
    }
  }

  let slug: String
  let title: String
  let subtitle: String
  let intro: [SpanDTO]?
  let link: LinkLabelDTO?
  let media: [MediaDTO]
  let chapters: [Chapter]
  let tags: [String]
}

struct LinkLabelDTO: Decodable {
  let label: String
  let url: String
}

// ─────────────────────────────────────────────────────────────────────────────
// Applications, expertise, parcours
// ─────────────────────────────────────────────────────────────────────────────

struct AppCatalogueDTO: Decodable {
  struct Item: Decodable {
    let slug: String
    let name: String
    let territory: String
    let appStoreUrl: String
    let role: String
  }

  let verifiedAt: String
  let items: [Item]
}

struct ExpertiseDTO: Decodable {
  let id: String
  let title: String
  let body: [SpanDTO]
}

struct ExperienceDTO: Decodable {
  let slug: String
  let role: String
  let organisation: String
  let location: String
  let start: String
  let end: String?
  let roles: [String]
  let highlights: [[SpanDTO]]
  let stack: [String]
}

struct BackgroundDTO: Decodable {
  struct Education: Decodable {
    let slug: String
    let degree: String
    let school: String
    let detail: String?
    let startYear: Int
    let endYear: Int
  }

  struct Certification: Decodable {
    let slug: String
    let name: String
    let issuer: String
    let awardedOn: String
    let verifyUrl: String?
  }

  struct OpenProject: Decodable {
    let slug: String
    let name: String
    let description: [SpanDTO]
    let sourceUrl: String?
  }

  let education: [Education]
  let certifications: [Certification]
  let openProjects: [OpenProject]
}

struct SkillGroupDTO: Decodable {
  let id: String
  let title: String
  let items: [String]
}
