import Domain
import Foundation

/// The crossing from transport to domain.
///
/// This is the one boundary where a string becomes a `YearMonth`, where a role
/// `String` becomes an enum case, and where a URL is validated. Everything
/// upstream accepts what the network sends; everything downstream works on
/// values whose shape is guaranteed.
///
/// An unexpected value **throws**. It does not fall back to a default case: an
/// unknown role filed under "features" would put an app in the wrong grid, and
/// that is the kind of mistake you only notice in an interview.
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

  // ── Rich text ──────────────────────────────────────────────────────────

  static func richText(_ spans: [SpanDTO]) -> RichText {
    RichText(spans: spans.map { span in
      RichText.Span(text: span.text, emphasis: emphasis(span.style))
    })
  }

  /// An unknown style falls back to plain text.
  ///
  /// Unlike an application role — where getting it wrong files an app in the
  /// wrong grid — getting the emphasis wrong changes **nothing about the
  /// meaning**. Failing the whole payload over a font weight would be out of
  /// proportion.
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

  /// A panel with an unknown `kind` is **dropped**, not fatal.
  ///
  /// The domain knows three — problem, decision, result — and its layout is
  /// built on them. A fourth kind would necessarily arrive with a version of the
  /// app that knows how to show it; until then, ignoring it beats refusing all
  /// the content.
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
            reason: .unknownValue(item.role)
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

  // ── Career ─────────────────────────────────────────────────────────────

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

  // ── Elementary conversions ─────────────────────────────────────────────

  /// `2023-05` or `2025` — and nothing else.
  static func yearMonth(_ raw: String, at path: String) throws(MappingError) -> YearMonth {
    let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
    guard let year = Int(parts[0]), parts[0].count == 4 else {
      throw MappingError(path: path, reason: .unreadableDate(raw))
    }
    switch parts.count {
    case 1:
      return YearMonth(year: year)
    case 2:
      guard let month = Int(parts[1]), (1...12).contains(month) else {
        throw MappingError(path: path, reason: .monthOutOfRange(String(parts[1])))
      }
      return YearMonth(year: year, month: month)
    default:
      throw MappingError(path: path, reason: .unreadableDate(raw))
    }
  }

  /// A URL is validated **here**, once, on the way in.
  ///
  /// The domain keeps a string: forcing `URL` on it would make every entity
  /// initialiser failable, and would carry a platform detail into the core of
  /// the app. The guarantee is given at the boundary, where we are still talking
  /// to the network.
  static func url(_ raw: String, at path: String) throws(MappingError) -> URLString {
    guard let url = URL(string: raw), url.scheme == "https" else {
      throw MappingError(path: path, reason: .insecureURL(raw))
    }
    return raw
  }
}
