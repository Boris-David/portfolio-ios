import Backstage
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The opening: a monogram, a name, one action.
///
/// ## What it stopped being, and why
///
/// It was a green-dotted pill reading "Open to opportunities", three
/// icon-and-text lines, and two buttons side by side. The owner's verdict was
/// exact: *"that's web, that's AI-generated."* And it is — that is the
/// vocabulary of a landing page, where a visitor arrives cold and has to be sold
/// something in one viewport.
///
/// An app opens differently. Somebody who launched it already decided to look;
/// the first screen owes them an **identity**, not a pitch. So: a monogram to
/// land the eye, the name, the signature, the role in one line, and **one**
/// primary action. The availability is a quiet line of text where it belongs,
/// not a floating badge demanding to be read first.
///
/// The long introduction moved to `AboutScreen`, one tap away. An opening gives
/// the scale; the story is for whoever wants it.
///
/// ## Why `ZStack` here and not anywhere else
///
/// Three genuine layers: a wash that bleeds behind the monogram, the content,
/// and the safe area. They overlap on purpose — a `VStack` would stack them,
/// which is the opposite of what is wanted. Used because it is the right tool,
/// not to have used it.
struct HeroBlock: View {
  let profile: Profile
  @Environment(Router.self) private var router
  @Environment(\.dynamicTypeSize) private var typeSize
  @ReducedMotion private var reducedMotion
  @Chrome private var chrome

  private var monogram: Monogram { Monogram(profile.name) }

  var body: some View {
    ZStack(alignment: .top) {
      wash
      content
    }
    .backstage(Self.heroNote)
  }

  /// A soft accent glow behind the monogram, bleeding past the reading column.
  ///
  /// Decorative, therefore hidden from VoiceOver and ignored for hit testing —
  /// a gradient that swallowed taps meant for the button underneath would be a
  /// defect nobody could see.
  private var wash: some View {
    RadialGradient(
      colors: [Color.accentWash.opacity(Tokens.Opacity.heroWash), Color.paper.opacity(0)],
      center: .top,
      startRadius: 0,
      endRadius: Tokens.Layout.heroWashRadius
    )
    .frame(height: Tokens.Layout.heroWashRadius)
    // Bleeds under the navigation bar rather than starting at it: a gradient
    // that begins exactly at a bar edge draws a visible band, which reads as a
    // seam. Only visible on screen.
    .ignoresSafeArea(edges: .top)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      identityCard
      availabilityLine
      primaryAction
      aboutLink
    }
    .padding(.horizontal, Tokens.Space.s5)
    .padding(.top, Tokens.Space.s6)
  }

  // ── The card ───────────────────────────────────────────────────────────

  /// ## Why `ViewThatFits`
  ///
  /// At the accessibility text sizes, a monogram beside a name stops fitting —
  /// the name wraps to three lines and the two columns fight over the width.
  /// `ViewThatFits` takes the stacked arrangement instead, and it does so by
  /// **measuring**, not by comparing against a size threshold somebody guessed.
  private var identityCard: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .center, spacing: Tokens.Space.s4) {
        monogramBadge
        nameAndRole
      }
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        monogramBadge
        nameAndRole
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(profile.name.full). \(profile.headline)")
  }

  private var monogramBadge: some View {
    Text(monogram.letters)
      .font(.system(size: Tokens.Icon.feature, weight: .semibold, design: .serif))
      .foregroundStyle(Color.accent)
      .frame(width: Tokens.Layout.monogramSide, height: Tokens.Layout.monogramSide)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
          .fill(Color.accentWash)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
          .strokeBorder(Color.accent.opacity(Tokens.Opacity.annotation), lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)
  }

  private var nameAndRole: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
      Text(profile.name.display)
        .font(Typography.hero)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)

      // The stroke draws under the name: a signature, not a decoration. It is
      // **decorative** in the accessibility sense — VoiceOver has nothing to
      // say about it — so it is hidden rather than announced as "image".
      LottieAnimation("signature", bundle: .coreUI)
        .frame(height: Tokens.Layout.signatureHeight)
        .frame(maxWidth: Tokens.Layout.signatureWidth, alignment: .leading)
        .accessibilityHidden(true)

      Text(profile.headline)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
    }
  }

  // ── The quiet facts ────────────────────────────────────────────────────

  /// Availability, location and languages as **one line of text**.
  ///
  /// They were three rows with icons — the shape a landing page uses to fill a
  /// column. On a phone they are one sentence, read in the order somebody
  /// actually needs them: is he available, where, in which languages.
  private var availabilityLine: some View {
    Text([profile.availability, profile.location, profile.languages].joined(separator: " · "))
      .font(Typography.caption)
      .foregroundStyle(Color.ink3)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityLabel(
        [profile.availability, profile.location, profile.languages].joined(separator: ", ")
      )
  }

  // ── One action, and one way in ─────────────────────────────────────────

  /// ## Why one button and not two
  ///
  /// Two equal buttons side by side is a page asking the reader to choose before
  /// they know anything. One primary action decides for them; the résumé is a
  /// permanent toolbar item on every screen, which is both more findable and
  /// less loud.
  private var primaryAction: some View {
    Button {
      router.present(.contact)
    } label: {
      Label(chrome.contactAction, icon: .contact)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.adaptiveGlassProminent)
    .backstage(Self.actionNote)
  }

  private var aboutLink: some View {
    NavigationLink(value: Route.about) {
      HStack(spacing: Tokens.Space.s2) {
        Text(chrome.aboutLink)
        Image(systemName: "arrow.right")
          .font(.system(size: Tokens.Icon.caption, weight: .semibold))
      }
      .font(Typography.secondary)
      .foregroundStyle(Color.accent)
    }
  }

  // ── Backstage ──────────────────────────────────────────────────────────

  static let heroNote = BackstageNote(
    id: "profile.hero",
    component: "ZStack · ViewThatFits",
    role: Bilingual(
      fr: "L'ouverture : un monogramme, un nom, une action.",
      en: "The opening: a monogram, a name, one action."
    ),
    rationale: Bilingual(
      fr: """
        La version précédente était une **page d'accueil web** : pastille verte \
        à point, trois lignes à icônes, deux boutons côte à côte. Ce vocabulaire \
        sert à vendre quelque chose à quelqu'un qui arrive froid.

        Une application s'ouvre autrement. Qui l'a lancée a déjà décidé de \
        regarder : le premier écran lui doit une **identité**, pas un argumentaire.

        `ZStack` porte trois couches qui se **chevauchent** vraiment — un halo \
        qui déborde de la colonne de lecture, le contenu, la zone sûre. \
        `ViewThatFits` mesure au lieu de comparer à un seuil : aux tailles \
        d'accessibilité, le monogramme passe au-dessus du nom tout seul.
        """,
      en: """
        The previous version was a **web landing page**: green-dotted pill, \
        three icon rows, two buttons side by side. That vocabulary exists to \
        sell something to somebody who arrived cold.

        An app opens differently. Whoever launched it already decided to look: \
        the first screen owes them an **identity**, not a pitch.

        `ZStack` carries three layers that genuinely **overlap** — a wash \
        bleeding past the reading column, the content, the safe area. \
        `ViewThatFits` measures rather than comparing against a threshold \
        somebody guessed: at the accessibility sizes the monogram moves above \
        the name on its own.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une photo", en: "A portrait photograph"),
        because: Bilingual(
          fr: "Plusieurs pays déconseillent explicitement la photo sur un CV : elle invite un jugement qui n'a rien à voir avec le travail. Le monogramme donne le même point d'ancrage.",
          en: "Several countries' hiring guidance advises against a CV photo: it invites a judgement that has nothing to do with the work. The monogram gives the same anchor."
        )
      ),
      .init(
        Bilingual(fr: "Deux boutons côte à côte", en: "Two buttons side by side"),
        because: Bilingual(
          fr: "Demander de choisir avant d'avoir rien lu. Le CV est désormais dans la barre d'outils de **tous** les écrans : plus trouvable, et moins bruyant.",
          en: "It asks the reader to choose before they have read anything. The résumé is now a toolbar item on **every** screen: more findable, and quieter."
        )
      ),
      .init(
        Bilingual(fr: "Un seuil de `sizeCategory`", en: "A `sizeCategory` threshold"),
        because: Bilingual(
          fr: "Un seuil est une supposition sur une largeur. `ViewThatFits` mesure la vraie.",
          en: "A threshold is a guess about a width. `ViewThatFits` measures the real one."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "`ZStack` quand les couches se chevauchent réellement — sinon c'est un `VStack` déguisé. `ViewThatFits` quand deux dispositions sont également valides et que seule la place tranche.",
      en: "`ZStack` when the layers genuinely overlap — otherwise it is a `VStack` in disguise. `ViewThatFits` when two arrangements are equally valid and only the room decides."
    ),
    pitfall: Bilingual(
      fr: "Un dégradé décoratif dans un `ZStack` intercepte les touches par défaut : sans `allowsHitTesting(false)`, il avale les taps destinés au bouton qu'il recouvre.",
      en: "A decorative gradient in a `ZStack` intercepts touches by default: without `allowsHitTesting(false)` it swallows taps meant for the button underneath."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/viewthatfits")
  )

  static let actionNote = BackstageNote(
    id: "profile.action",
    component: "Button · adaptiveGlassProminent",
    role: Bilingual(
      fr: "L'unique action principale de l'écran d'ouverture.",
      en: "The opening screen's one primary action."
    ),
    rationale: Bilingual(
      fr: """
        Une action principale par écran, au plus. Deux boutons de même poids ne \
        sont pas deux fois plus utiles : ils annulent la hiérarchie et le lecteur \
        doit arbitrer à la place du concepteur.

        Le style se rend différemment sur les deux mondes — verre teinté sur \
        iOS 26, aplat d'accent sur iOS 18 — parce que la même teinte à faible \
        opacité sur un matériau translucide donne du blanc sur du pâle en thème \
        clair. Mesuré à l'écran, pas supposé.
        """,
      en: """
        One primary action per screen, at most. Two buttons of equal weight are \
        not twice as useful: they cancel the hierarchy, and the reader ends up \
        arbitrating in the designer's place.

        The style renders differently in the two worlds — tinted glass on \
        iOS 26, a solid accent fill on iOS 18 — because the same tint at low \
        opacity over a translucent material gives white on pale in light theme. \
        Measured on screen, not assumed.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "`.borderedProminent`", en: "`.borderedProminent`"),
        because: Bilingual(
          fr: "Il ignore Liquid Glass sur iOS 26 : le bouton aurait l'air d'iOS 17 au milieu d'une barre en verre.",
          en: "It ignores Liquid Glass on iOS 26: the button would look like iOS 17 in the middle of a glass bar."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "L'action que l'écran existe pour proposer. S'il y en a deux, l'une des deux n'en est pas une.",
      en: "The action the screen exists to offer. If there are two, one of them is not one."
    ),
    pitfall: Bilingual(
      fr: "`glassEffect` s'applique à la vue, jamais en arrière-plan : posé dans un `.background`, il **recouvre** le libellé et le bouton paraît vide.",
      en: "`glassEffect` applies to the view, never as a background: put in `.background`, it **covers** the label and the button looks empty."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/buttonstyle")
  )
}

/// The publishable figures, and only those.
struct MetricsBlock: View {
  let metrics: [Metric]

  var body: some View {
    VStack(spacing: Tokens.Space.s4) {
      ForEach(metrics) { metric in
        Surface(.recessed) {
          MetricTile(
            value: metric.value,
            unit: metric.unit,
            caption: metric.caption,
            countTo: metric.countTo
          )
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
    .backstage(
      BackstageNote(
        id: "profile.metrics",
        component: "contentTransition(.numericText())",
        role: Bilingual(
          fr: "Fait défiler les chiffres qui se comptent, sans que la tuile tremble.",
          en: "Rolls the counting figures without the tile jittering."
        ),
        rationale: Bilingual(
          fr: """
            Un nombre qui change de valeur change aussi de **largeur** : les \
            chiffres n'ont pas tous la même. Sans précaution, la tuile tremble \
            pendant tout le décompte.

            Deux modificateurs y répondent ensemble. `.monospacedDigit()` fige la \
            largeur de chaque chiffre ; `.contentTransition(.numericText())` \
            demande au système d'interpoler les glyphes plutôt que de les \
            remplacer, ce qui donne le défilement mécanique d'un compteur.

            Et le décompte n'est pas décidé ici : c'est un champ du contenu. \
            « ~5 M » **pourrait** se compter — on choisit que non, parce \
            qu'animer une approximation lui donne une précision qu'elle n'a pas.
            """,
          en: """
            A number that changes value also changes **width**: digits are not \
            all the same size. Left alone, the tile jitters through the whole \
            count.

            Two modifiers answer this together. `.monospacedDigit()` fixes each \
            digit's width; `.contentTransition(.numericText())` asks the system \
            to interpolate glyphs rather than replace them, which gives the \
            mechanical roll of an odometer.

            And the counting is not decided here: it is a content field. “~5 M” \
            **could** count up — we choose not to, because animating an \
            approximation lends it a precision it does not have.
            """
        ),
        rejected: [
          .init(
            Bilingual(fr: "Un `Timer` qui incrémente", en: "A `Timer` that increments"),
            because: Bilingual(
              fr: "il tourne à sa propre cadence, indépendante du rafraîchissement de l'écran — le décompte saute sur un appareil chargé",
              en: "it runs at its own cadence, independent of the display refresh — the count stutters on a busy device"
            )
          ),
          .init(
            Bilingual(fr: "Animer la valeur sans `monospacedDigit`", en: "Animating the value without `monospacedDigit`"),
            because: Bilingual(
              fr: "la largeur change à chaque image et tout le bloc se décale",
              en: "the width changes every frame and the whole block shifts"
            )
          ),
        ],
        whenToUse: Bilingual(
          fr: """
            Dès qu'un nombre change **à l'écran** et que la transition doit se \
            voir : un score, un compteur, un prix. Pour un nombre statique, ces \
            deux modificateurs ne coûtent rien mais n'apportent rien.
            """,
          en: """
            Whenever a number changes **on screen** and the transition should be \
            seen: a score, a counter, a price. For a static number, both \
            modifiers cost nothing and add nothing.
            """
        ),
        documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)")
      )
    )
  }
}

/// The three subjects dug into.
struct ExpertiseBlock: View {
  let section: Portfolio.Section?
  let topics: [ExpertiseTopic]
  @Environment(Router.self) private var router

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      if let section {
        SectionHeader(
          eyebrow: section.eyebrow,
          title: section.title,
          intro: section.intro?.plain
        )
      }
      ForEach(topics) { topic in
        Button {
          router.push(.expertise(id: topic.id))
        } label: {
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
              HStack {
                Text(topic.title)
                  .font(Typography.heading)
                  .foregroundStyle(Color.ink)
                Spacer(minLength: Tokens.Space.s3)
                Image(systemName: "chevron.right")
                  .font(.footnote.weight(.semibold))
                  .foregroundStyle(Color.ink3)
              }
              Text(topic.body.plain)
                .font(Typography.secondary)
                .foregroundStyle(Color.ink2)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            }
          }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

/// A subject's detail.
struct ExpertiseDetailView: View {
  let topic: ExpertiseTopic

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        Text(topic.title)
          .font(Typography.title)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)
        RichTextView(topic.body)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s5)
    }
    .background(Color.paper)
    .navigationTitle(topic.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// The one published contact channel.
struct ContactBlock: View {
  let contact: Profile.Contact
  @Environment(\.openURL) private var openURL

  var body: some View {
    Surface(.raised) {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        Text(contact.title)
          .font(Typography.title)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(contact.body)
          .font(Typography.body)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)

        Button {
          if let url = URL(string: "mailto:\(contact.email)") { openURL(url) }
        } label: {
          Label(contact.email, systemImage: "envelope")
        }
        .buttonStyle(.adaptiveGlassProminent)

        WrappingRow {
          ForEach(contact.links) { link in
            Button {
              if let url = URL(string: link.url) { openURL(url) }
            } label: {
              Label(link.label, systemImage: symbol(for: link.id))
                .font(Typography.secondary)
            }
            .buttonStyle(.adaptiveGlass)
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }

  /// SF Symbols does not cover brands: GitHub and LinkedIn are not in it.
  /// Rather than embedding logos — whose use their owners govern — a generic
  /// symbol is used, and the **label** carries the identification.
  private func symbol(for id: String) -> String {
    switch id {
    case "github": "chevron.left.forwardslash.chevron.right"
    case "linkedin": "person.2"
    default: "link"
    }
  }
}
