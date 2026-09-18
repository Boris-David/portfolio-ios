import Backstage
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The projects, told the way an engineer delivers: the problem, the decision,
/// the result.
public struct WorkScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Chrome private var chrome

  public init() {}

  public var body: some View {
    SectionShell(title: chrome.tabWork) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot.portfolio)
      }
    }
  }

  private func content(_ portfolio: Portfolio) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        if let section = portfolio.section("case-studies") {
          SectionHeader(
            eyebrow: section.eyebrow,
            title: section.title,
            intro: section.intro?.plain
          )
          .padding(.horizontal, Tokens.Space.s5)
        }

        VStack(spacing: Tokens.Space.s4) {
          ForEach(portfolio.caseStudies) { study in
            CaseStudyCard(study: study)
          }
        }
        .padding(.horizontal, Tokens.Space.s5)

        AppsBlock(
          section: portfolio.section("apps"),
          catalogue: portfolio.apps
        )
      }
      .padding(.top, Tokens.Space.s4)
      .padding(.bottom, Tokens.Space.s8)
      .readableWidth()
    }
    .refreshable { await store.refresh() }
  }
}

/// A case study's card: collapsed it gives the scale, expanded it gives the
/// detail.
struct CaseStudyCard: View {
  let study: CaseStudy
  @Environment(Router.self) private var router
  @Chrome private var chrome

  var body: some View {
    Button {
      router.push(.caseStudy(slug: study.slug))
    } label: {
      Surface {
        VStack(alignment: .leading, spacing: Tokens.Space.s3) {
          Text(study.subtitle).eyebrowStyle()
          Text(study.title)
            .font(Typography.heading)
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

          if let intro = study.intro {
            Text(intro.plain)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .lineLimit(3)
              .multilineTextAlignment(.leading)
          }

          WrappingRow {
            ForEach(study.tags.prefix(6), id: \.self) { tag in
              Chip(tag)
            }
            if study.tags.count > 6 {
              Chip("+\(study.tags.count - 6)", emphasis: .accented)
            }
          }

          HStack(spacing: Tokens.Space.s2) {
            Text(study.hasNamedChapters
              ? chrome.chapterCount(study.chapters.count)
              : chrome.readStudy)
              .font(Typography.caption)
              .foregroundStyle(Color.accent)
            Image(systemName: "arrow.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(Color.accent)
          }
          .padding(.top, Tokens.Space.s1)
        }
      }
    }
    .buttonStyle(.plain)
    .reveal()
  }
}

/// The grid of production apps.
struct AppsBlock: View {
  let section: Portfolio.Section?
  let catalogue: AppCatalogue
  @Chrome private var chrome

  private let columns = [GridItem(.adaptive(minimum: 150), spacing: Tokens.Space.s3)]

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      if let section {
        SectionHeader(
          eyebrow: section.eyebrow,
          title: section.title,
          intro: section.intro?.plain
        )
      }

      LazyVGrid(columns: columns, spacing: Tokens.Space.s3) {
        ForEach(catalogue.ticketing) { app in
          AppCell(app: app)
        }
      }
      .backstage(Self.gridNote)

      if let note = section?.note {
        Text(note.plain)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
          .fixedSize(horizontal: false, vertical: true)
      }

      Text(chrome.verifiedOn(catalogue.verifiedOn))
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }

  static let gridNote = BackstageNote(
    id: "work.grid",
    component: "LazyVGrid · GridItem(.adaptive)",
    role: Bilingual(
      fr: "Dispose les applications en colonnes qui s'adaptent à la largeur.",
      en: "Lays the apps out in columns that adapt to the available width."
    ),
    rationale: Bilingual(
      fr: """
        `.adaptive(minimum:)` laisse **le système** choisir le nombre de \
        colonnes selon la place : deux sur un iPhone compact, trois sur un Pro \
        Max, davantage sur un iPad. Une seule déclaration couvre toutes les \
        tailles, et surtout toutes les tailles de **texte** — en accessibilité \
        extra-large, la grille retombe à une colonne toute seule.

        `Lazy` compte ici : les cellules ne sont créées qu'en approchant de \
        l'écran. Avec trente-trois entrées portant chacune une image, tout \
        construire d'un coup se verrait au premier défilement.
        """,
      en: """
        `.adaptive(minimum:)` lets **the system** pick the column count from the \
        space available: two on a compact iPhone, three on a Pro Max, more on an \
        iPad. One declaration covers every size — and above all every **text** \
        size: at accessibility extra-large the grid falls back to one column on \
        its own.

        `Lazy` matters here: cells are only built as they approach the screen. \
        With thirty-three entries each carrying an image, building them all at \
        once would show on the first scroll.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`.fixed()` ou un nombre de colonnes codé en dur", en: "`.fixed()` or a hard-coded column count"),
        because: Bilingual(
          fr: "il faudrait une valeur par classe de taille, et elles seraient toutes fausses en accessibilité extra-large",
          en: "it would need one value per size class, and all of them would be wrong at accessibility extra-large"
        )
      ),
      .init(
        Bilingual(fr: "`VGrid` non paresseux", en: "A non-lazy `VGrid`"),
        because: Bilingual(
          fr: "trente-trois cellules et leurs images construites d'un coup, pour deux visibles",
          en: "thirty-three cells and their images built at once, for two on screen"
        )
      ),
      .init(
        Bilingual(fr: "Un `List`", en: "A `List`"),
        because: Bilingual(
          fr: "une ligne par application donnerait trois écrans de défilement là où la grille montre l'échelle d'un coup d'œil — et l'échelle est l'information",
          en: "one row per app would take three screens of scrolling where the grid shows the scale at a glance — and the scale is the information"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        `.adaptive` dès que le nombre de colonnes n'est pas une décision \
        éditoriale mais une conséquence de la place. `.flexible` quand le nombre \
        de colonnes **est** la décision — une comparaison à deux colonnes, par \
        exemple.
        """,
      en: """
        `.adaptive` whenever the column count is not an editorial decision but a \
        consequence of available space. `.flexible` when the column count **is** \
        the decision — a two-column comparison, for instance.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `minimum:` est la largeur minimale d'une **colonne**, espacement non \
        compris. Une valeur trop basse produit six colonnes illisibles sur iPad \
        sans qu'aucune contrainte ne s'en plaigne.
        """,
      en: """
        `minimum:` is the minimum width of a **column**, spacing excluded. Too \
        low a value produces six unreadable columns on iPad without any \
        constraint complaining.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/griditem")
  )
}

struct AppCell: View {
  let app: ProductionApp
  @Environment(\.openURL) private var openURL
  @Chrome private var chrome

  var body: some View {
    Button {
      if let url = URL(string: app.appStoreURL) { openURL(url) }
    } label: {
      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        AppIconView(slug: app.slug)
        Text(app.name)
          .font(Typography.bodyStrong)
          .foregroundStyle(Color.ink)
          .lineLimit(1)
        Text(app.territory)
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s3)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .fill(Color.paper2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular)
      )
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(app.name), \(app.territory)")
    .accessibilityHint(chrome.openInAppStore)
  }
}

/// An app's icon, named by its **public slug**.
///
/// Never by an internal network identifier: those do not leave the building, and
/// an image path is public content just as much as a sentence is.
struct AppIconView: View {
  let slug: String

  var body: some View {
    ContentImage(slug, kind: .appIcon)
      .frame(width: Tokens.Layout.appIconSide, height: Tokens.Layout.appIconSide)
      .clipShape(RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Layout.appIconRadius, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)
  }
}
