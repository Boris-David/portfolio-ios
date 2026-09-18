import Domain
import Foundation

/// Le passage du transport au domaine.
///
/// C'est la seule frontière où une chaîne devient un `YearMonth`, où un `String`
/// de rôle devient un cas d'énumération, et où une URL est validée. Tout ce qui
/// est en amont accepte ce que le réseau envoie ; tout ce qui est en aval
/// travaille sur des valeurs dont la forme est garantie.
///
/// Une valeur inattendue **lève**. Elle ne se replie pas sur un cas par défaut :
/// un rôle inconnu rangé en « fonctionnalités » ferait apparaître une
/// application dans la mauvaise grille, et c'est le genre d'erreur qu'on ne
/// voit qu'en entretien.
enum PortfolioMapping {
  static func portfolio(from dto: PortfolioDTO) throws(MappingError) -> Portfolio {
    Portfolio(
      profile: try profile(from: dto.profile),
      metrics: dto.metrics.map(metric),
      sections: dto.sections.map(section),
      caseStudies: dto.caseStudies.map(caseStudy),
      apps: try appCatalogue(from: dto.apps),
      expertise: dto.expertise.map(expertise),
      experience: try dto.experience.map(experience),
      background: try background(from: dto.background),
      skills: dto.skills.map { SkillGroup(id: $0.id, title: $0.title, items: $0.items) }
    )
  }

  // ── Texte riche ────────────────────────────────────────────────────────

  static func richText(_ spans: [SpanDTO]) -> RichText {
    RichText(spans: spans.map { span in
      RichText.Span(text: span.text, emphasis: emphasis(span.style))
    })
  }

  /// Un style inconnu retombe sur « texte ».
  ///
  /// Contrairement à un rôle d'application — où se tromper range une
  /// application dans la mauvaise grille — se tromper d'emphase ne change
  /// **rien au sens**. Faire échouer toute la charge utile pour une graisse
  /// serait disproportionné.
  private static func emphasis(_ style: String) -> RichText.Span.Emphasis {
    switch style {
    case "strong": .strong
    case "code": .code
    default: .plain
    }
  }

  // ── Profil ─────────────────────────────────────────────────────────────

  static func profile(from dto: ProfileDTO) throws(MappingError) -> Profile {
    Profile(
      name: Profile.Name(display: dto.name.display, full: dto.name.full),
      headline: dto.headline,
      availability: dto.availability,
      location: dto.location,
      remote: dto.remote,
      languages: dto.languages,
      summary: dto.summary.map(richText),
      showcase: Profile.Showcase(
        media: media(dto.showcase.media),
        caseStudySlug: dto.showcase.caseStudy
      ),
      contact: Profile.Contact(
        email: dto.contact.email,
        title: dto.contact.title,
        body: dto.contact.body,
        links: try dto.contact.links.map { link throws(MappingError) in
          ProfileLink(
            id: link.id,
            label: link.label,
            url: try url(link.url, at: "profile.contact.links[\(link.id)].url")
          )
        }
      ),
      footer: Profile.Footer(role: dto.footer.role, location: dto.footer.location)
    )
  }

  static func media(_ dto: MediaDTO) -> Media {
    Media(id: dto.id, alt: dto.alt, caption: dto.caption)
  }

  // ── Chiffres et sections ───────────────────────────────────────────────

  static func metric(_ dto: MetricDTO) -> Metric {
    Metric(id: dto.id, value: dto.value, unit: dto.unit, countTo: dto.countTo, caption: dto.caption)
  }

  static func section(_ dto: SectionDTO) -> Portfolio.Section {
    Portfolio.Section(
      id: dto.id,
      eyebrow: dto.eyebrow,
      title: dto.title,
      intro: dto.intro.map(richText),
      note: dto.note.map(richText)
    )
  }

  // ── Études de cas ──────────────────────────────────────────────────────

  static func caseStudy(_ dto: CaseStudyDTO) -> CaseStudy {
    CaseStudy(
      slug: dto.slug,
      title: dto.title,
      subtitle: dto.subtitle,
      intro: dto.intro.map(richText),
      link: dto.link.map { CaseStudy.Link(label: $0.label, url: $0.url) },
      media: dto.media.map(media),
      chapters: dto.chapters.map { chapter in
        CaseStudy.Chapter(
          slug: chapter.slug,
          title: chapter.title,
          subtitle: chapter.subtitle,
          panels: chapter.panels.compactMap(panel)
        )
      },
      tags: dto.tags
    )
  }

  /// Un panneau dont le `kind` est inconnu est **écarté**, pas fatal.
  ///
  /// Le domaine n'en connaît que trois — problème, décision, résultat — et sa
  /// mise en page est bâtie dessus. Un quatrième type viendrait forcément avec
  /// une version de l'application qui sait l'afficher ; d'ici là, l'ignorer
  /// vaut mieux que refuser tout le contenu.
  static func panel(_ dto: CaseStudyDTO.Panel) -> CaseStudy.Panel? {
    guard let kind = CaseStudy.Panel.Kind(rawValue: dto.kind) else { return nil }
    return CaseStudy.Panel(
      kind: kind,
      heading: dto.heading,
      blocks: dto.blocks.map { block in
        switch block {
        case .paragraph(let spans): .paragraph(richText(spans))
        case .list(let items): .list(items.map(richText))
        case .tags(let items): .tags(items)
        }
      }
    )
  }

  // ── Applications ───────────────────────────────────────────────────────

  static func appCatalogue(from dto: AppCatalogueDTO) throws(MappingError) -> AppCatalogue {
    AppCatalogue(
      verifiedOn: dto.verifiedAt,
      items: try dto.items.map { item throws(MappingError) in
        guard let role = ProductionApp.Role(rawValue: item.role) else {
          throw MappingError(
            path: "apps.items[\(item.slug)].role",
            reason: "rôle « \(item.role) » inconnu"
          )
        }
        return ProductionApp(
          slug: item.slug,
          name: item.name,
          territory: item.territory,
          appStoreURL: try url(item.appStoreUrl, at: "apps.items[\(item.slug)].appStoreUrl"),
          role: role
        )
      }
    )
  }

  static func expertise(_ dto: ExpertiseDTO) -> ExpertiseTopic {
    ExpertiseTopic(id: dto.id, title: dto.title, body: richText(dto.body))
  }

  // ── Parcours ───────────────────────────────────────────────────────────

  static func experience(_ dto: ExperienceDTO) throws(MappingError) -> Experience {
    Experience(
      slug: dto.slug,
      role: dto.role,
      organisation: dto.organisation,
      location: dto.location,
      start: try yearMonth(dto.start, at: "experience[\(dto.slug)].start"),
      end: try dto.end.map { value throws(MappingError) in
        try yearMonth(value, at: "experience[\(dto.slug)].end")
      },
      sideRoles: dto.roles,
      highlights: dto.highlights.map(richText),
      stack: dto.stack
    )
  }

  static func background(from dto: BackgroundDTO) throws(MappingError) -> Background {
    Background(
      education: dto.education.map {
        Education(
          slug: $0.slug,
          degree: $0.degree,
          school: $0.school,
          detail: $0.detail,
          startYear: $0.startYear,
          endYear: $0.endYear
        )
      },
      certifications: try dto.certifications.map { item throws(MappingError) in
        Certification(
          slug: item.slug,
          name: item.name,
          issuer: item.issuer,
          awardedOn: try yearMonth(
            item.awardedOn,
            at: "background.certifications[\(item.slug)].awardedOn"
          ),
          verifyURL: item.verifyUrl
        )
      },
      openProjects: dto.openProjects.map {
        OpenProject(
          slug: $0.slug,
          name: $0.name,
          description: richText($0.description),
          sourceURL: $0.sourceUrl
        )
      }
    )
  }

  // ── Conversions élémentaires ───────────────────────────────────────────

  /// `2023-05` ou `2025` — et rien d'autre.
  static func yearMonth(_ raw: String, at path: String) throws(MappingError) -> YearMonth {
    let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
    guard let year = Int(parts[0]), parts[0].count == 4 else {
      throw MappingError(path: path, reason: "date « \(raw) » illisible — « AAAA » ou « AAAA-MM » attendu")
    }
    switch parts.count {
    case 1:
      return YearMonth(year: year)
    case 2:
      guard let month = Int(parts[1]), (1...12).contains(month) else {
        throw MappingError(path: path, reason: "mois « \(parts[1]) » hors de 01–12")
      }
      return YearMonth(year: year, month: month)
    default:
      throw MappingError(path: path, reason: "date « \(raw) » illisible — trop de composants")
    }
  }

  /// Une URL est validée **ici**, une fois, à l'entrée.
  ///
  /// Le domaine garde une chaîne : lui imposer `URL` obligerait chaque
  /// constructeur d'entité à pouvoir échouer, et ferait remonter un détail de
  /// plateforme au cœur de l'application. La garantie est apportée à la
  /// frontière, là où l'on parle encore au réseau.
  static func url(_ raw: String, at path: String) throws(MappingError) -> URLString {
    guard let url = URL(string: raw), url.scheme == "https" else {
      throw MappingError(path: path, reason: "« \(raw) » n'est pas une URL https")
    }
    return raw
  }
}

/// Une valeur de la source que le domaine ne peut pas accepter, **et où**.
struct MappingError: Error, Sendable, Hashable {
  let path: String
  let reason: String
}
