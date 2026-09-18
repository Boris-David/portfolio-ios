import Backstage
import DesignSystem
import Domain
import FeatureKit
import SwiftUI

/// L'accroche : disponibilité, nom, métier, et la capture qui illustre.
struct HeroBlock: View {
  let profile: Profile
  @Environment(Router.self) private var router
  @ReducedMotion private var reducedMotion
  @Chrome private var chrome

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      availability

      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        Text(profile.headline).eyebrowStyle()
        Text(profile.name.display)
          .font(Typography.hero)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)

        // Le trait se dessine sous le nom : une signature, pas une décoration.
        // Il est **décoratif** au sens de l'accessibilité — VoiceOver n'a rien
        // à en dire — donc il est masqué plutôt qu'annoncé « image ».
        LottieAnimationView("signature", bundle: .designSystem)
          .frame(height: 34)
          .frame(maxWidth: 260, alignment: .leading)
          .accessibilityHidden(true)
      }
      .accessibilityElement(children: .combine)
      // L'annotation porte sur le **bloc** nom + signature, pas sur la vue
      // Lottie seule.
      //
      // Deux raisons. La note décrit le traitement de l'accroche dans son
      // ensemble, pas un composant isolé. Et surtout : un `UIViewRepresentable`
      // ne rapporte pas toujours le cadre qu'on lui impose — l'ancre relevée
      // sur la vue Lottie désignait une bande vide sous elle, ce qu'on n'a vu
      // qu'en dessinant la zone annotée à l'écran.
      .backstage(Self.lottieNote)

      VStack(alignment: .leading, spacing: Tokens.Space.s3) {
        ForEach(Array(profile.summary.enumerated()), id: \.offset) { _, paragraph in
          RichTextView(paragraph)
        }
      }

      identity
      actions
    }
    .padding(.horizontal, Tokens.Space.s5)
    .padding(.top, Tokens.Space.s5)
  }

  private var availability: some View {
    HStack(spacing: Tokens.Space.s2) {
      Circle()
        .fill(Color.ok)
        .frame(width: 8, height: 8)
      Text(profile.availability)
        .font(Typography.caption)
        .foregroundStyle(Color.ink2)
    }
    .padding(.horizontal, Tokens.Space.s3)
    .padding(.vertical, Tokens.Space.s2)
    .background(Capsule().fill(Color.paper2))
    .overlay(Capsule().strokeBorder(Color.line, lineWidth: 1))
    .accessibilityElement(children: .combine)
  }

  private var identity: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      row("mappin.and.ellipse", profile.location)
      row("house", profile.remote)
      row("globe", profile.languages)
    }
  }

  private func row(_ symbol: String, _ label: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
      Image(systemName: symbol)
        .font(.footnote)
        .foregroundStyle(Color.accent)
        .frame(width: 18)
      Text(label)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
        .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .combine)
  }

  private var actions: some View {
    GlassGroup {
      HStack(spacing: Tokens.Space.s3) {
        Button {
          router.present(.contact)
        } label: {
          Label(chrome.contactAction, systemImage: "envelope")
        }
        .buttonStyle(.adaptiveGlassProminent)

        Button {
          router.present(.resume)
        } label: {
          Label(chrome.resumeAction, systemImage: "doc.text")
        }
        .buttonStyle(.adaptiveGlass)
      }
    }
    .backstage(Self.glassNote)
  }

  // ── Coulisses ──────────────────────────────────────────────────────────

  static let lottieNote = BackstageNote(
    id: "profile.lottie",
    component: "Lottie · LottieAnimationView",
    role: Bilingual(
      fr: "Dessine le trait sous le nom, une fois, à l'ouverture.",
      en: "Draws the stroke under the name, once, on open."
    ),
    rationale: Bilingual(
      fr: """
        Ce trait est une **courbe de Bézier animée par un tracé progressif** \
        (*trim path*). Ni SwiftUI ni Core Animation ne savent lire un tel \
        fichier : il faudrait réimplémenter un interpréteur d'animations After \
        Effects.

        C'est la règle qu'on s'applique partout ici : *une dépendance se \
        justifie par ce qui serait pire sans elle, pas par ce qu'elle rend \
        pratique.* Sans Lottie, c'est réellement pire. Sans Alamofire, non — \
        d'où l'un et pas l'autre.

        Le fichier lui-même est écrit à la main, et sa couleur est **lue dans \
        les tokens de design** : l'accent du trait est exactement l'accent du \
        site.
        """,
      en: """
        This stroke is a **Bézier curve animated by a trim path**. Neither \
        SwiftUI nor Core Animation can read such a file: you would have to \
        reimplement an After Effects animation interpreter.

        It is the rule applied everywhere here: *a dependency earns its place \
        by what would be worse without it, not by what it makes convenient.* \
        Without Lottie it really is worse. Without Alamofire it is not — hence \
        one and not the other.

        The file itself is hand-authored, and its colour is **read from the \
        design tokens**: the stroke's accent is exactly the site's accent.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une animation SwiftUI sur `trim(from:to:)`", en: "A SwiftUI animation on `trim(from:to:)`"),
        because: Bilingual(
          fr: "possible pour ce trait-ci, mais il faudrait redéfinir la courbe en Swift — donc la maintenir à deux endroits, alors qu'elle est dessinée ailleurs",
          en: "doable for this one stroke, but the curve would have to be redefined in Swift — kept in two places, while it is drawn elsewhere"
        )
      ),
      .init(
        Bilingual(fr: "Un GIF ou une vidéo", en: "A GIF or a video"),
        because: Bilingual(
          fr: "pixellisé à l'échelle, sans transparence propre, et impossible à teinter depuis les tokens",
          en: "pixelated when scaled, no clean transparency, and impossible to tint from the tokens"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Pour une animation **vectorielle** conçue par un designer, avec des \
        tracés, des masques ou des trajectoires. Pour un mouvement simple — une \
        opacité, une translation, un ressort — SwiftUI suffit largement et pèse \
        zéro octet.
        """,
      en: """
        For a **vector** animation authored by a designer, with paths, masks or \
        motion along a curve. For simple motion — opacity, translation, a \
        spring — SwiftUI is plenty and weighs nothing.
        """
    ),
    pitfall: Bilingual(
      fr: """
        La vue Lottie impose sa **taille intrinsèque** si on ne baisse pas ses \
        priorités de compression : une animation plus grande que sa place fait \
        alors exploser la mise en page autour d'elle, sans erreur ni \
        avertissement.
        """,
      en: """
        The Lottie view imposes its **intrinsic size** unless you lower its \
        compression priorities: an animation larger than its slot then blows up \
        the surrounding layout, with no error and no warning.
        """
    ),
    documentation: URL(string: "https://airbnb.io/lottie/#/ios")
  )

  static let glassNote = BackstageNote(
    id: "profile.glass",
    component: "GlassEffectContainer · glassEffect",
    role: Bilingual(
      fr: "Regroupe les deux boutons flottants pour qu'ils partagent une seule couche de verre.",
      en: "Groups both floating buttons so they share a single glass layer."
    ),
    rationale: Bilingual(
      fr: """
        Deux boutons de verre côte à côte sans conteneur sont deux verres \
        **empilés** : le fond est échantillonné deux fois, et le rendu \
        s'assombrit à leur intersection. `GlassEffectContainer` les fusionne en \
        une couche.

        L'application vise **iOS 18 et plus** tout en se compilant avec le SDK \
        d'iOS 26. Plutôt que de semer des `if #available` dans les vues — où \
        personne ne saurait plus ce que voit un utilisateur d'iOS 18 — \
        l'intention est nommée (`.navigationGlass()`) et le rendu décidé à un \
        seul endroit.

        Sur iOS 18, le repli n'est pas « la même chose en moins bien » : c'est \
        le matériau que le système emploie lui-même pour ses barres.
        """,
      en: """
        Two glass buttons side by side without a container are two **stacked** \
        panes: the backdrop is sampled twice and darkens where they overlap. \
        `GlassEffectContainer` merges them into one layer.

        The app targets **iOS 18 and later** while compiling against the iOS 26 \
        SDK. Rather than scattering `if #available` through the views — where \
        nobody would know what an iOS 18 user actually sees — the intent is \
        named (`.navigationGlass()`) and the rendering decided in one place.

        On iOS 18 the fallback is not “the same thing, worse”: it is the \
        material the system itself uses for its bars.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Ne cibler qu'iOS 26", en: "Targeting iOS 26 only"),
        because: Bilingual(
          fr: "exclut les appareils qui n'ont pas franchi la version majeure — une part qui se compte en dizaines de pour cent les premiers mois",
          en: "excludes devices that have not moved to the major release — tens of percent in the first months"
        )
      ),
      .init(
        "`.background(.ultraThinMaterial)`",
        because: Bilingual(
          fr: "partout, l'application aurait l'air d'iOS 18 sur iOS 26, en renonçant au matériau du système",
          en: "used everywhere, the app would look like iOS 18 on iOS 26, giving up the system material"
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: """
        Liquid Glass est un matériau de la couche **navigation** : barres, \
        contrôles flottants, accessoires. Posé sur du contenu — une liste, un \
        paragraphe, une image — il dégrade le contraste et brouille la \
        hiérarchie : tout se met à flotter, donc plus rien ne ressort.
        """,
      en: """
        Liquid Glass is a material of the **navigation** layer: bars, floating \
        controls, accessories. Applied to content — a list, a paragraph, an \
        image — it degrades contrast and blurs hierarchy: everything floats, so \
        nothing stands out.
        """
    ),
    pitfall: Bilingual(
      fr: """
        `glassEffect(in:)` découpe selon la forme donnée. Sans forme explicite, \
        c'est le rectangle englobant — et un bouton en capsule se retrouve avec \
        des coins de verre carrés qui dépassent.
        """,
      en: """
        `glassEffect(in:)` clips to the shape you pass. With no explicit shape \
        it is the bounding rectangle — and a capsule button ends up with square \
        glass corners sticking out.
        """
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/glasseffectcontainer")
  )
}

/// Les chiffres publiables, et eux seuls.
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

/// Les trois sujets creusés.
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

/// Le détail d'un sujet.
struct ExpertiseDetail: View {
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

/// Le seul canal de contact publié.
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

  /// Les symboles SF ne couvrent pas les marques : GitHub et LinkedIn n'y sont
  /// pas. Plutôt qu'embarquer des logos — dont l'usage est encadré par leurs
  /// propriétaires — on emploie un symbole générique, et le **libellé** porte
  /// l'identification.
  private func symbol(for id: String) -> String {
    switch id {
    case "github": "chevron.left.forwardslash.chevron.right"
    case "linkedin": "person.2"
    default: "link"
    }
  }
}
