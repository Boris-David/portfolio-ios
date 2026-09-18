import Backstage
import DesignSystem
import Domain
import FeatureKit
import SwiftUI

/// Le parcours : expériences, formation, certifications, compétences.
public struct JourneyScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Chrome private var chrome

  public init() {}

  public var body: some View {
    SectionShell(title: chrome.tabJourney) {
      switch store.state {
      case .loading:
        LoadingSkeleton()
      case .failed(let failure):
        ContentUnavailableScreen(failure: failure) { store.load() }
      case .ready(let snapshot):
        content(snapshot.portfolio)
      }
    }
  }

  private func content(_ portfolio: Portfolio) -> some View {
    let dates = DateStyle(language: store.language)

    return ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        if let section = portfolio.section("background") {
          SectionHeader(eyebrow: section.eyebrow, title: section.title)
            .padding(.horizontal, Tokens.Space.s5)
        }

        VStack(spacing: Tokens.Space.s3) {
          ForEach(Array(portfolio.experience.enumerated()), id: \.element.id) { index, job in
            ExperienceCard(job: job, dates: dates, startsOpen: index == 0)
          }
        }
        .padding(.horizontal, Tokens.Space.s5)
        .backstage(Self.timelineNote)

        TimelineBlock(
          title: chrome.education,
          rows: portfolio.background.education.map { entry in
            TimelineRow(
              when: dates.years(entry.startYear, entry.endYear),
              what: entry.degree,
              detail: entry.detail.map { "\(entry.school) — \($0)" } ?? entry.school,
              link: nil
            )
          }
        )

        TimelineBlock(
          title: chrome.certifications,
          rows: portfolio.background.certifications.map { entry in
            TimelineRow(
              when: dates.long(entry.awardedOn),
              what: entry.name,
              detail: entry.issuer,
              link: entry.verifyURL.flatMap(URL.init(string:)).map {
                TimelineRow.Link(label: chrome.verifyCertificate, url: $0)
              }
            )
          }
        )

        TimelineBlock(
          title: chrome.openProjects,
          rows: portfolio.background.openProjects.map { project in
            TimelineRow(
              when: nil,
              what: project.name,
              detail: project.description.plain,
              link: project.sourceURL.flatMap(URL.init(string:)).map {
                TimelineRow.Link(label: chrome.sourceCode, url: $0)
              }
            )
          }
        )

        SkillsBlock(groups: portfolio.skills)
      }
      .padding(.top, Tokens.Space.s4)
      .padding(.bottom, Tokens.Space.s8)
    }
    .refreshable { await store.refresh() }
  }

  static let timelineNote = BackstageNote(
    id: "journey.timeline",
    component: "DateFormatter · shortMonthSymbols",
    role: Bilingual(
      fr: "Transforme « 2023-05 » en « mai 2023 », dans la langue affichée.",
      en: "Turns “2023-05” into “May 2023”, in the language on screen."
    ),
    rationale: Bilingual(
      fr: """
        La source sert des dates **machine** : `start: "2023-05"`, `end: null`. \
        Elle ne sert jamais « mai 2023 → aujourd'hui », et c'est délibéré — la \
        chaîne lisible dépend de la langue, du contexte et de la place, et la \
        figer à la source la figerait pour le site, le CV en PDF et cette \
        application à la fois.

        Un seul détail ne s'obtient pas directement : le **point d'abréviation**. \
        Le français le porte déjà (« janv. »), l'anglais non (« Jan »), et \
        « mai » comme « May » n'en prennent aucun puisqu'ils ne sont pas abrégés. \
        D'où une règle unique pour les deux langues : *une forme courte qui \
        diffère de la forme longue est une abréviation, et une abréviation prend \
        un point.*

        C'est exactement la règle du site, qui l'obtient d'`Intl`. Les deux \
        plateformes affichent donc la même chaîne — pas « à peu près la même ».
        """,
      en: """
        The source serves **machine** dates: `start: "2023-05"`, `end: null`. It \
        never serves “May 2023 → today”, and that is deliberate — the readable \
        string depends on language, context and available width, and fixing it \
        at the source would fix it for the site, the PDF résumé and this app at \
        once.

        One detail is not available directly: the **abbreviation period**. \
        French already carries it (“janv.”), English does not (“Jan”), and \
        “mai” like “May” take none since they are not abbreviated. Hence a \
        single rule for both languages: *a short form that differs from the long \
        form is an abbreviation, and an abbreviation takes a period.*

        It is exactly the site's rule, which gets it from `Intl`. Both platforms \
        therefore print the same string — not “roughly the same”.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une table de mois par langue", en: "A month table per language"),
        because: Bilingual(
          fr: "douze entrées × deux langues à tenir, et une faute d'abréviation ne se voit qu'en production",
          en: "twelve entries × two languages to maintain, and an abbreviation mistake only shows in production"
        )
      ),
      .init(
        Bilingual(fr: "Servir la chaîne déjà formatée depuis l'API", en: "Serving a pre-formatted string from the API"),
        because: Bilingual(
          fr: "elle deviendrait la même pour le PDF, le site et l'app — et aucun des trois n'a la même place",
          en: "it would be the same for the PDF, the site and the app — and none of the three has the same room"
        )
      ),
      .init(
        Bilingual(fr: "`Date` plutôt que `YearMonth`", en: "`Date` rather than `YearMonth`"),
        because: Bilingual(
          fr: "une `Date` porte une heure et un fuseau : « mai 2023 » devient avril 2023 quelque part sur la planète",
          en: "a `Date` carries a time and a zone: “May 2023” becomes April 2023 somewhere on the planet"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Dès qu'une date doit s'afficher : toujours par un formateur localisé, \
        jamais par concaténation. Et dans le modèle, le type le plus **grossier** \
        qui suffise — une date de diplôme n'a pas besoin de secondes.
        """,
      en: """
        Whenever a date is displayed: always through a localised formatter, never \
        by concatenation. And in the model, the **coarsest** type that suffices — \
        a graduation date has no need for seconds.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `DateFormatter` est coûteux à construire et n'est pas `Sendable`. En \
        créer un par cellule de liste se mesure au défilement ; ici il vit dans \
        une valeur créée une fois par écran.
        """,
      en: """
        `DateFormatter` is expensive to build and is not `Sendable`. Creating one \
        per list cell is measurable while scrolling; here it lives in a value \
        created once per screen.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/foundation/dateformatter")
  )
}

/// Une expérience, dépliable.
struct ExperienceCard: View {
  let job: Experience
  let dates: DateStyle
  let startsOpen: Bool

  @State private var isOpen: Bool?
  @ReducedMotion private var reducedMotion
  @Chrome private var chrome

  /// La plus récente est ouverte à l'arrivée — c'est celle qu'on vient lire.
  /// `nil` veut dire « pas encore décidé par l'utilisateur », ce qui laisse
  /// l'état initial dépendre du rang sans le figer.
  private var open: Bool { isOpen ?? startsOpen }

  var body: some View {
    Surface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        header
        details
      }
    }
  }

  private var header: some View {
    Button {
      withAnimation(reducedMotion ? nil : Motion.disclosure) { isOpen = !open }
    } label: {
      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        HStack(alignment: .top) {
          Text(dates.range(from: job.start, to: job.end)).eyebrowStyle()
          Spacer(minLength: Tokens.Space.s2)
          Image(systemName: "chevron.down")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.ink3)
            .rotationEffect(.degrees(open ? 0 : -90))
        }
        Text(job.role)
          .font(Typography.heading)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.leading)
        Text("\(job.organisation) · \(job.location)")
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .multilineTextAlignment(.leading)

        if !job.sideRoles.isEmpty {
          WrappingRow {
            ForEach(job.sideRoles, id: \.self) { Chip($0, emphasis: .accented) }
          }
          .padding(.top, Tokens.Space.s1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("\(job.role), \(job.organisation)")
    .accessibilityValue(open ? chrome.expanded : chrome.collapsed)
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Divider().overlay(Color.line)
      ForEach(Array(job.highlights.enumerated()), id: \.offset) { _, highlight in
        HStack(alignment: .top, spacing: Tokens.Space.s3) {
          Circle()
            .fill(Color.accent)
            .frame(width: 5, height: 5)
            .padding(.top, 8)
          RichTextView(highlight)
        }
      }
      if !job.stack.isEmpty {
        WrappingRow {
          ForEach(job.stack, id: \.self) { Chip($0) }
        }
        .padding(.top, Tokens.Space.s2)
      }
    }
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.bottom, Tokens.Space.s4)
    .frame(height: open ? nil : 0, alignment: .top)
    .opacity(open ? 1 : 0)
    .clipped()
    .accessibilityHidden(!open)
  }
}

/// Une ligne de chronologie — formation, certification, projet.
struct TimelineRow: Identifiable {
  struct Link {
    let label: String
    let url: URL
  }

  var id: String { what }
  let when: String?
  let what: String
  let detail: String
  let link: Link?
}

struct TimelineBlock: View {
  let title: String
  let rows: [TimelineRow]
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(title).eyebrowStyle()
      VStack(spacing: Tokens.Space.s3) {
        ForEach(rows) { row in
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s1) {
              if let when = row.when {
                Text(when)
                  .font(Typography.caption)
                  .foregroundStyle(Color.accent)
                  .monospacedDigit()
              }
              Text(row.what)
                .font(Typography.bodyStrong)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
              Text(row.detail)
                .font(Typography.secondary)
                .foregroundStyle(Color.ink2)
                .fixedSize(horizontal: false, vertical: true)
              if let link = row.link {
                Button {
                  openURL(link.url)
                } label: {
                  Label(link.label, systemImage: "checkmark.seal")
                    .font(Typography.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accent)
                .padding(.top, Tokens.Space.s1)
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

struct SkillsBlock: View {
  let groups: [SkillGroup]
  @Chrome private var chrome

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(chrome.skills).eyebrowStyle()
      ForEach(groups) { group in
        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
          Text(group.title)
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
          WrappingRow {
            ForEach(group.items, id: \.self) { Chip($0) }
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}
