import Backstage
import DesignSystem
import Domain
import FeatureKit
import SwiftUI
import ViewKit

/// Une étude de cas en entier.
///
/// Deux mises en page pour un seul modèle, discriminées par une propriété du
/// **récit** et non par un champ technique : un chapitre qui porte un titre est
/// un chantier qu'on peut nommer et déplier ; un chapitre anonyme est le corps
/// unique d'une histoire, qui se lit d'une traite.
public struct CaseStudyDetail: View {
  private let study: CaseStudy
  @Environment(\.openURL) private var openURL

  public init(study: CaseStudy) {
    self.study = study
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s5) {
        header

        if study.hasNamedChapters {
          VStack(spacing: Tokens.Space.s3) {
            ForEach(Array(study.chapters.enumerated()), id: \.element.id) { index, chapter in
              ChapterDisclosure(number: index + 1, chapter: chapter)
            }
          }
          .backstage(Self.disclosureNote)
        } else if let chapter = study.chapters.first {
          FlatChapter(chapter: chapter)
        }

        if !study.media.isEmpty {
          Gallery(media: study.media)
        }

        WrappingRow {
          ForEach(study.tags, id: \.self) { Chip($0) }
        }
      }
      .padding(Tokens.Space.s5)
      .padding(.bottom, Tokens.Space.s8)
    }
    .background(Color.paper)
    .navigationTitle(study.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(study.subtitle).eyebrowStyle()
      Text(study.title)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let intro = study.intro {
        RichTextView(intro)
      }
      if let link = study.link {
        Button {
          if let url = URL(string: link.url) { openURL(url) }
        } label: {
          Label(link.label, systemImage: "arrow.up.right")
        }
        .buttonStyle(.adaptiveGlass)
        .padding(.top, Tokens.Space.s1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  static let disclosureNote = BackstageNote(
    id: "work.disclosure",
    component: "Dépliage sur mesure · clipped",
    role: Bilingual(
      fr: "Déplie un chantier sans faire sauter la mise en page autour de lui.",
      en: "Expands a workstream without making the surrounding layout jump."
    ),
    rationale: Bilingual(
      fr: """
        Le dépliage anime une **hauteur**, et c'est le cas le plus piégeux de \
        SwiftUI : animer `frame(height:)` demande de connaître la hauteur finale \
        avant de l'afficher, ce qu'on ne sait pas d'un texte de longueur \
        variable.

        La solution ici est de laisser le contenu **exister** en permanence et \
        de n'animer que ce qui est mesurable : opacité et hauteur nulle, sous un \
        `.clipped()`. La hauteur réelle est laissée à SwiftUI, qui l'interpole \
        dès lors que le changement est dans une `withAnimation`.

        Conséquence heureuse : le texte replié est **dans l'arbre de vues**. La \
        recherche système le trouve, et VoiceOver peut l'atteindre.
        """,
      en: """
        Expansion animates a **height**, the trickiest case in SwiftUI: \
        animating `frame(height:)` requires knowing the final height before \
        showing it, which you cannot know for text of variable length.

        The answer here is to let the content **exist** at all times and animate \
        only what is measurable: opacity and a zero height, under a \
        `.clipped()`. The real height is left to SwiftUI, which interpolates it \
        as long as the change happens inside `withAnimation`.

        A happy consequence: the collapsed text is **in the view tree**. System \
        search finds it, and VoiceOver can reach it.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`DisclosureGroup` natif", en: "The built-in `DisclosureGroup`"),
        because: Bilingual(
          fr: "son chevron, ses marges et son animation ne se redéfinissent pas assez pour tenir le design, et son étiquette n'accepte pas de mise en page libre",
          en: "its chevron, insets and animation cannot be redefined enough to hold the design, and its label does not take a free-form layout"
        )
      ),
      .init(
        Bilingual(fr: "Ajouter et retirer la vue de l'arbre", en: "Adding and removing the view from the tree"),
        because: Bilingual(
          fr: "le contenu replié disparaît de la recherche et de VoiceOver, et la transition part de rien — donc elle saute",
          en: "collapsed content disappears from search and VoiceOver, and the transition starts from nothing — so it jumps"
        )
      ),
      .init(
        Bilingual(fr: "Animer `frame(height:)` mesuré par `GeometryReader`", en: "Animating `frame(height:)` measured by `GeometryReader`"),
        because: Bilingual(
          fr: "une mesure par image, un aller-retour de mise en page à chaque fois, et un saut au premier affichage avant que la mesure n'existe",
          en: "one measurement per frame, a layout round trip each time, and a jump on first display before the measurement exists"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Ce motif dès qu'un bloc de **hauteur inconnue** doit s'ouvrir et se \
        fermer. Si la hauteur est connue et fixe, animer `frame` directement est \
        plus simple et parfaitement correct.
        """,
      en: """
        This pattern whenever a block of **unknown height** must open and close. \
        If the height is known and fixed, animating `frame` directly is simpler \
        and perfectly correct.
        """
    ),
    pitfall: Bilingual(
      fr: """
        Sans `.clipped()`, le contenu replié **déborde** de son conteneur pendant \
        l'animation et passe par-dessus les cartes voisines. On ne le voit que \
        sur un appareil lent, ou en enregistrant l'écran au ralenti.
        """,
      en: """
        Without `.clipped()`, collapsed content **overflows** its container \
        during the animation and paints over neighbouring cards. You only see it \
        on a slow device, or by recording the screen in slow motion.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/disclosuregroup")
  )
}

/// Un chantier dépliable.
struct ChapterDisclosure: View {
  let number: Int
  let chapter: CaseStudy.Chapter

  @State private var isOpen = false
  @ReducedMotion private var reducedMotion
  @Chrome private var chrome

  var body: some View {
    Surface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        summary
        body_
      }
    }
  }

  private var summary: some View {
    Button {
      withAnimation(reducedMotion ? nil : Motion.disclosure) { isOpen.toggle() }
    } label: {
      HStack(alignment: .top, spacing: Tokens.Space.s3) {
        Text(String(format: "%02d", number))
          .font(Typography.code)
          .foregroundStyle(Color.accent)
          .monospacedDigit()

        VStack(alignment: .leading, spacing: 2) {
          Text(chapter.title ?? "")
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
          if let subtitle = chapter.subtitle {
            Text(subtitle)
              .font(Typography.caption)
              .foregroundStyle(Color.ink3)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        Spacer(minLength: Tokens.Space.s2)

        Image(systemName: "chevron.down")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(Color.ink3)
          .rotationEffect(.degrees(isOpen ? 0 : -90))
          .padding(.top, 2)
      }
      .padding(Tokens.Space.s4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(chapter.title ?? "")
    .accessibilityValue(isOpen ? chrome.expanded : chrome.collapsed)
    
  }

  /// Le corps reste dans l'arbre de vues même replié — seule sa hauteur tombe à
  /// zéro. C'est ce qui garde le texte trouvable par la recherche système et
  /// atteignable par VoiceOver, et ce qui permet à la transition de partir
  /// d'un état qui existe.
  private var body_: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Divider().overlay(Color.line)
      ForEach(CaseStudy.Panel.Kind.allCases, id: \.self) { kind in
        if let panel = chapter.panel(kind) {
          PanelView(panel: panel)
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.bottom, Tokens.Space.s4)
    .frame(height: isOpen ? nil : 0, alignment: .top)
    .opacity(isOpen ? 1 : 0)
    // Sans découpe, le contenu replié déborde par-dessus la carte suivante
    // pendant toute l'animation.
    .clipped()
    .accessibilityHidden(!isOpen)
  }
}

/// Un récit qui se lit d'une traite — trois colonnes empilées.
struct FlatChapter: View {
  let chapter: CaseStudy.Chapter

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      ForEach(CaseStudy.Panel.Kind.allCases, id: \.self) { kind in
        if let panel = chapter.panel(kind) {
          Surface { PanelView(panel: panel) }
        }
      }
    }
  }
}

/// Un panneau : son intitulé, son corps, ses étiquettes.
struct PanelView: View {
  let panel: CaseStudy.Panel

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(panel.heading).eyebrowStyle()
      ForEach(Array(panel.prose.enumerated()), id: \.offset) { _, paragraph in
        RichTextView(paragraph)
      }
      if !panel.tags.isEmpty {
        WrappingRow {
          ForEach(panel.tags, id: \.self) { Chip($0, emphasis: .accented) }
        }
        .padding(.top, Tokens.Space.s1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Les captures d'écran, en défilement horizontal.
struct Gallery: View {
  let media: [Media]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Tokens.Space.s3) {
        ForEach(media) { item in
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            Image(item.id, bundle: .main)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: 380)
              .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                  .strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular)
              )
              .accessibilityLabel(item.alt)
            Text(item.caption)
              .font(Typography.caption)
              .foregroundStyle(Color.ink3)
          }
        }
      }
      .scrollTargetLayout()
    }
    // Le défilement s'arrête sur une capture, jamais entre deux : une galerie
    // qui s'immobilise à cheval donne l'impression d'être cassée.
    .scrollTargetBehavior(.viewAligned)
    .scrollClipDisabled()
  }
}
