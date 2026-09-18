import CoreUI
import Domain
import Foundation
import Presentation

/// What this app says about itself.
///
/// ## Why this particular content is not in the API
///
/// The test is the same as for the website: *content is what would still be true
/// if this client did not exist.* A fact about his career stays true without the
/// app — it goes to the API. "Why an actor rather than a lock in **this** app"
/// means nothing without it: that is architecture documentation, it lives with
/// the code it describes, and it becomes wrong in the same commit.
package enum AppDossier {
  // ───────────────────────────────────────────────────────────────────────
  // The layers
  // ───────────────────────────────────────────────────────────────────────

  public struct Layer: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let responsibility: Bilingual
    /// What it depends on — and nothing more. The SPM manifest enforces it.
    public let dependsOn: [String]
    public let rule: Bilingual
  }

  public static let layers: [Layer] = [
    Layer(
      id: "domain",
      name: "Domain",
      responsibility: Bilingual(
        fr: "Les entités et les ports. Ce que l'application *est*.",
        en: "The entities and the ports. What the app *is*."
      ),
      dependsOn: [],
      rule: Bilingual(
        fr: """
          Ne dépend de **rien** : ni transport, ni stockage, ni SwiftUI, ni \
          format de sérialisation. C'est la seule couche qui survivrait à un \
          changement complet des trois autres.
          """,
        en: """
          Depends on **nothing**: no transport, no storage, no SwiftUI, no \
          serialisation format. It is the only layer that would survive \
          replacing all three others.
          """
      )
    ),
    Layer(
      id: "networking",
      name: "Networking",
      responsibility: Bilingual(fr: "Parler HTTP. Rien d'autre.", en: "Speak HTTP. Nothing else."),
      dependsOn: [],
      rule: Bilingual(
        fr: """
          Ne connaît pas le portfolio. Aucun de ses types ne mentionne un profil \
          ou une étude de cas — c'est ce qui permet de la tester sans rien \
          savoir du domaine, et de la remplacer sans rouvrir une ligne ailleurs.
          """,
        en: """
          Knows nothing of the portfolio. None of its types mentions a profile \
          or a case study — which is what lets it be tested without knowing the \
          domain, and replaced without reopening a line elsewhere.
          """
      )
    ),
    Layer(
      id: "persistence",
      name: "Persistence",
      responsibility: Bilingual(
        fr: "Écrire et relire des octets, de façon sérialisée.",
        en: "Write and read back bytes, serialised."
      ),
      dependsOn: [],
      rule: Bilingual(
        fr: """
          Un acteur, pas un verrou : l'isolation devient une propriété du type, \
          et l'oubli devient impossible plutôt qu'improbable.
          """,
        en: """
          An actor, not a lock: isolation becomes a property of the type, and \
          forgetting becomes impossible rather than unlikely.
          """
      )
    ),
    Layer(
      id: "data",
      name: "Data",
      responsibility: Bilingual(
        fr: "Les *gateways* : DTO, correspondances, dépôts, sources.",
        en: "The *gateways*: DTOs, mapping, repositories, sources."
      ),
      dependsOn: ["Domain", "Networking", "Persistence"],
      rule: Bilingual(
        fr: """
          Le seul endroit où le domaine et la technique se rencontrent. Les DTO \
          vivent ici, **jamais** dans `Domain` : une entité qui porte des \
          `CodingKeys` est une entité qui a laissé le réseau dicter sa forme.
          """,
        en: """
          The one place where domain and plumbing meet. DTOs live here, \
          **never** in `Domain`: an entity carrying `CodingKeys` is an entity \
          that let the network dictate its shape.
          """
      )
    ),
    Layer(
      id: "designsystem",
      name: "DesignSystem",
      responsibility: Bilingual(
        fr: "Couleurs, typographie, mouvement, composants.",
        en: "Colours, typography, motion, components."
      ),
      dependsOn: [],
      rule: Bilingual(
        fr: """
          Ne connaît pas le domaine non plus. Ses valeurs sont **générées** \
          depuis `design/tokens.json`, la même source que le CSS du site : les \
          deux affichent la même valeur hexadécimale, pas « à peu près la même ».
          """,
        en: """
          Knows nothing of the domain either. Its values are **generated** from \
          `design/tokens.json`, the same source as the site's CSS: both render \
          the same hexadecimal value, not “roughly the same”.
          """
      )
    ),
    Layer(
      id: "presentation",
      name: "Presentation",
      responsibility: Bilingual(
        fr: "Décider ce qu'un écran montre — jamais le dessiner.",
        en: "Decide what a screen shows — never draw it."
      ),
      dependsOn: ["Domain"],
      rule: Bilingual(
        fr: """
          **N'importe pas SwiftUI.** C'est le test décisif d'une couche de \
          présentation : si ça dessine, c'est une vue ; si ça décide quoi \
          dessiner, c'est ici. Conséquence directe — phases, messages d'erreur, \
          formats de date et routes se testent **sans simulateur**.
          """,
        en: """
          **Does not import SwiftUI.** That is the acid test of a presentation \
          layer: if it draws, it is a view; if it decides what to draw, it \
          belongs here. Direct consequence — phases, failure messages, date \
          formats and routes are tested **with no simulator**.
          """
      )
    ),
    Layer(
      id: "features",
      name: "Features",
      responsibility: Bilingual(
        fr: "Un écran, son état, ses annotations.",
        en: "One screen, its state, its annotations."
      ),
      dependsOn: ["Domain", "Presentation", "DesignSystem"],
      rule: Bilingual(
        fr: """
          Ne voient **ni** `Networking`, **ni** `Persistence`, **ni** `Data`. \
          Une vue parle à un port du domaine ; ce qui l'implémente est décidé \
          ailleurs. Ce n'est pas une convention : ces trois noms sont absents du \
          manifeste de ce package, et `import Networking` répond « no such \
          module ».
          """,
        en: """
          See **neither** `Networking`, **nor** `Persistence`, **nor** `Data`. A \
          view talks to a domain port; what implements it is decided elsewhere. \
          This is not a convention: those three names are absent from this \
          package's manifest, and `import Networking` answers “no such module”.
          """
      )
    ),
    Layer(
      id: "composition",
      name: "Composition",
      responsibility: Bilingual(
        fr: "Brancher les implémentations sur les ports.",
        en: "Wire implementations onto the ports."
      ),
      dependsOn: ["Domain", "Networking", "Persistence", "Data", "Presentation", "DesignSystem", "Features"],
      rule: Bilingual(
        fr: """
          Le seul package qui a le droit de tout voir, parce que quelqu'un doit \
          décider quel objet concret répond à quel protocole. Sa liste de \
          dépendances est longue, et celle de tous les autres est courte : \
          c'est exactement ce qu'on veut lire.
          """,
        en: """
          The only package allowed to see everything, because someone has to \
          decide which concrete object answers which protocol. Its dependency \
          list is long and everybody else's is short: that is exactly what you \
          want to read.
          """
      )
    ),
  ]

  // ───────────────────────────────────────────────────────────────────────
  // The challenges
  // ───────────────────────────────────────────────────────────────────────

  public struct Challenge: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: Bilingual
    public let problem: Bilingual
    public let solution: Bilingual
    public let lesson: Bilingual
  }

  public static let challenges: [Challenge] = [
    Challenge(
      id: "coalescing",
      title: Bilingual(fr: "Quatre écrans, une seule requête", en: "Four screens, one request"),
      problem: Bilingual(
        fr: """
          Les quatre onglets demandent le contenu en apparaissant. Sans \
          coordination, ce sont quatre requêtes simultanées, quatre écritures de \
          cache concurrentes — donc un fichier à moitié écrit — et deux versions \
          possibles à l'écran en même temps.

          Personne ne le verrait jamais. C'est précisément ce qui rend ce défaut \
          coûteux : il se manifeste une fois sur cent, chez quelqu'un d'autre.
          """,
        en: """
          All four tabs ask for the content as they appear. With no \
          coordination that is four simultaneous requests, four concurrent cache \
          writes — hence a half-written file — and two possible versions on \
          screen at once.

          Nobody would ever see it. That is exactly what makes this defect \
          expensive: it shows up once in a hundred runs, on someone else's \
          device.
          """
      ),
      solution: Bilingual(
        fr: """
          Un **acteur** porte l'état du dépôt, et il **mémorise la tâche de \
          rafraîchissement en cours**. Les appels concurrents n'en lancent pas \
          une nouvelle : ils attendent la même. Un seul aller-retour, quel que \
          soit le nombre de demandeurs.

          Un verrou aurait protégé l'état à condition qu'on pense à le prendre \
          partout — rien ne le vérifie — et un verrou tenu pendant une attente \
          asynchrone est un blocage qui n'attend que son heure.
          """,
        en: """
          An **actor** holds the repository's state, and it **remembers the \
          in-flight refresh task**. Concurrent callers do not start a new one: \
          they await the same one. A single round trip, however many ask.

          A lock would have protected the state provided you remembered to take \
          it everywhere — nothing checks that — and a lock held across an await \
          is a deadlock waiting to happen.
          """
      ),
      lesson: Bilingual(
        fr: """
          C'est le même mécanisme que celui posé en production sur \
          l'authentification d'un réseau de transport : plusieurs requêtes \
          recevant un « non autorisé » en même temps déclenchaient chacune leur \
          rafraîchissement de jeton, et les rafraîchissements concurrents \
          s'invalidaient entre eux. Mémoriser la tâche en cours a réglé les \
          déconnexions inexpliquées.
          """,
        en: """
          It is the same mechanism shipped to production on a transit network's \
          authentication: several requests receiving “unauthorised” at the same \
          time each triggered their own token refresh, and the concurrent \
          refreshes invalidated one another. Remembering the in-flight task \
          ended the unexplained sign-outs.
          """
      )
    ),
    Challenge(
      id: "offline",
      title: Bilingual(fr: "Afficher quelque chose dans un tunnel", en: "Showing something in a tunnel"),
      problem: Bilingual(
        fr: """
          Une application qui attend le réseau pour afficher quoi que ce soit est \
          inutilisable dans un métro — et c'est exactement là qu'on ouvre un \
          portfolio entre deux entretiens.
          """,
        en: """
          An app that waits for the network before showing anything is useless \
          on the underground — which is exactly where a portfolio gets opened \
          between two interviews.
          """
      ),
      solution: Bilingual(
        fr: """
          Trois couches, lues dans cet ordre : le **cache disque** de la dernière \
          session, la **graine embarquée** produite à la construction depuis \
          l'API, puis le **réseau**. L'écran s'affiche immédiatement avec ce \
          qu'il a, puis se met à jour.

          Et il **dit** ce qu'il affiche. Une application hors ligne qui ne \
          l'avoue pas montre du vieux contenu avec l'aplomb du neuf.
          """,
        en: """
          Three layers, read in this order: the **disk cache** from the last \
          session, the **bundled seed** produced at build time from the API, \
          then the **network**. The screen shows immediately with what it has, \
          then updates.

          And it **says** what it is showing. An offline app that does not admit \
          it presents stale content with the confidence of fresh content.
          """
      ),
      lesson: Bilingual(
        fr: """
          Le site, lui, **refuse** tout repli : il se construit sur une machine \
          qui a le réseau, et publier des sections vides serait pire qu'un \
          déploiement rouge. Le même principe — « pas de repli silencieux » — \
          donne deux décisions opposées selon le contexte. C'est le principe qui \
          se transporte, pas la décision.
          """,
        en: """
          The website, by contrast, **refuses** any fallback: it builds on a \
          machine that has the network, and publishing empty sections would be \
          worse than a red deployment. The same principle — “no silent \
          fallback” — yields opposite decisions depending on context. The \
          principle travels, the decision does not.
          """
      )
    ),
    Challenge(
      id: "compat",
      title: Bilingual(
        fr: "Liquid Glass sur iOS 26, sans abandonner iOS 18",
        en: "Liquid Glass on iOS 26, without dropping iOS 18"
      ),
      problem: Bilingual(
        fr: """
          Le SDK d'iOS 26 apporte un matériau que les versions antérieures n'ont \
          pas. Semer des `if #available` dans les vues fonctionne — et au bout \
          de trente écrans, plus personne ne sait ce que voit un utilisateur \
          d'iOS 18. Le repli n'est testé nulle part parce qu'il n'est nommé \
          nulle part.
          """,
        en: """
          The iOS 26 SDK brings a material earlier versions do not have. \
          Scattering `if #available` through the views works — and after thirty \
          screens nobody knows what an iOS 18 user actually sees. The fallback \
          is tested nowhere because it is named nowhere.
          """
      ),
      solution: Bilingual(
        fr: """
          L'**intention** est nommée — `.navigationGlass()` dit « ceci est une \
          surface de navigation » — et le rendu est décidé dans un seul fichier. \
          Le coût d'un SDK qui évolue se paie une fois, au lieu d'être réparti \
          partout.

          Sur iOS 18, le repli n'est pas « la même chose en moins bien » : c'est \
          le matériau que le système emploie lui-même pour ses barres.
          """,
        en: """
          The **intent** is named — `.navigationGlass()` says “this is a \
          navigation surface” — and the rendering is decided in a single file. \
          The cost of an evolving SDK is paid once instead of spread everywhere.

          On iOS 18 the fallback is not “the same thing, worse”: it is the \
          material the system itself uses for its bars.
          """
      ),
      lesson: Bilingual(
        fr: """
          Les deux rendus sont vérifiables : l'application se lance sur un \
          simulateur iOS 18 **et** sur un iOS 26, et les captures des deux sont \
          produites par la même commande.
          """,
        en: """
          Both renderings are verifiable: the app launches on an iOS 18 \
          simulator **and** on an iOS 26 one, and screenshots of both come from \
          the same command.
          """
      )
    ),
    Challenge(
      id: "boundaries",
      title: Bilingual(
        fr: "Une frontière que le compilateur tient",
        en: "A boundary the compiler holds"
      ),
      problem: Bilingual(
        fr: """
          « Les vues ne doivent pas connaître le réseau » est une règle d'équipe. \
          Les règles d'équipe se contournent le vendredi soir, et le \
          contournement ne se voit pas en revue quand le fichier fait huit cents \
          lignes.
          """,
        en: """
          “Views must not know about the network” is a team rule. Team rules get \
          bypassed on a Friday evening, and the bypass is invisible in review \
          when the file runs to eight hundred lines.
          """
      ),
      solution: Bilingual(
        fr: """
          Chaque couche est un **package SPM**, avec son propre manifeste. Une \
          cible aurait suffi à moitié : ajouter une ligne au manifeste commun \
          et la frontière tombait. Un package ne peut pas atteindre ce qu'il ne \
          déclare pas — `Features/Package.swift` ne nomme jamais `Networking`, \
          donc `import Networking` répond **« no such module »**.
          """,
        en: """
          Every layer is an **SPM package**, with its own manifest. A target \
          would only have got halfway: one line added to the shared manifest and \
          the boundary was gone. A package cannot reach what it does not \
          declare — `Features/Package.swift` never names `Networking`, so \
          `import Networking` answers **“no such module”**.
          """
      ),
      lesson: Bilingual(
        fr: """
          Et le graphe lui-même est sous test : `ArchitectureTests` lit les \
          huit manifestes et échoue si une couche gagne une dépendance \
          interdite. Deux invariants qu'aucun manifeste ne peut tenir — le \
          domaine ignore SwiftUI, la présentation ne dessine pas — sont refusés \
          par `Scripts/check-layers.sh`, parce que SwiftUI vient du SDK.
          """,
        en: """
          And the graph itself is under test: `ArchitectureTests` reads all \
          eight manifests and fails if a layer gains a forbidden dependency. Two \
          invariants no manifest can hold — the domain ignores SwiftUI, the \
          presentation does not draw — are refused by \
          `Scripts/check-layers.sh`, because SwiftUI ships with the SDK.
          """
      )
    ),
  ]

  // ───────────────────────────────────────────────────────────────────────
  // The dependencies, and why
  // ───────────────────────────────────────────────────────────────────────

  public struct DependencyCall: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let verdict: Verdict
    public let reasoning: Bilingual

    public enum Verdict: Sendable, Hashable {
      case adopted(version: String)
      case declined
    }
  }

  /// The rule, once and for all: *a dependency is justified by what would be
  /// worse without it, not by what it makes convenient.*
  public static let dependencies: [DependencyCall] = [
    DependencyCall(
      id: "lottie",
      name: "Lottie",
      verdict: .adopted(version: "4.6.x"),
      reasoning: Bilingual(
        fr: """
          Sans elle, il faudrait réimplémenter un interpréteur d'animations \
          After Effects — tracés de Bézier interpolés, masques, trajectoires. Ce \
          n'est pas « moins pratique », c'est un projet à soi seul. **Ce serait \
          réellement pire sans.**
          """,
        en: """
          Without it you would have to reimplement an After Effects animation \
          interpreter — interpolated Bézier paths, masks, motion along curves. \
          That is not “less convenient”, it is a project of its own. **It really \
          would be worse without.**
          """
      )
    ),
    DependencyCall(
      id: "alamofire",
      name: "Alamofire",
      verdict: .declined,
      reasoning: Bilingual(
        fr: """
          Excellente bibliothèque — dont on n'utiliserait rien ici. \
          L'`async/await` vient d'`URLSession` depuis iOS 15 ; la validation \
          tient en une comparaison de statut ; le rejeu et la politique de \
          fraîcheur vivent dans la couche `Data`, parce que réessayer est une \
          décision métier (« combien de temps un recruteur attend-il ? ») et pas \
          une décision de transport ; et l'application ne fait que lire.

          Ce qu'on paierait est réel : une dépendance de plus à auditer sur un \
          dépôt public, un binaire plus gros, une surface d'API à expliquer à \
          l'oral. Le protocole `HTTPClient` rend le choix **réversible** : le \
          jour où il faudrait ce qu'Alamofire apporte, une implémentation de \
          plus suffirait, sans qu'aucune vue ne bouge.
          """,
        en: """
          An excellent library — of which nothing would be used here. \
          `async/await` has come from `URLSession` since iOS 15; validation is \
          one status comparison; retry and freshness policy live in the `Data` \
          layer, because retrying is a product decision (“how long does a \
          recruiter wait?”) rather than a transport one; and the app only reads.

          What it would cost is real: one more dependency to audit on a public \
          repository, a larger binary, an API surface to explain out loud. The \
          `HTTPClient` protocol keeps the choice **reversible**: the day \
          Alamofire's features were needed, one more implementation would do it, \
          without a single view moving.
          """
      )
    ),
    DependencyCall(
      id: "textual",
      name: "Textual",
      verdict: .adopted(version: "0.5.x"),
      reasoning: Bilingual(
        fr: """
          `AttributedString(markdown:)` ne gère que l'**inline** — gras, code, \
          liens. Il ignore les listes et les blocs de code, qui sont exactement \
          ce dont une explication technique a besoin.

          Textual rend vers `AttributedString` **native** : on garde Dynamic \
          Type, la sélection et le rendu de texte du système, au lieu d'un arbre \
          de vues reconstruit. MarkdownUI, du même auteur, est passé en mode \
          maintenance et renvoie explicitement ici.

          C'est une version **0.x** : le semver ne promet rien avant la 1.0. \
          D'où `upToNextMinor` et non `from` — on accepte les correctifs, on \
          **décide** des montées de version.
          """,
        en: """
          `AttributedString(markdown:)` handles **inline** only — bold, code, \
          links. It ignores lists and code blocks, which are exactly what a \
          technical explanation needs.

          Textual renders to **native** `AttributedString`: you keep Dynamic \
          Type, selection and the system's text engine, instead of a rebuilt \
          view tree. MarkdownUI, by the same author, moved to maintenance mode \
          and points here explicitly.

          It is a **0.x** version: semver promises nothing before 1.0. Hence \
          `upToNextMinor` rather than `from` — patches are accepted, version \
          bumps are **decided**.
          """
      )
    ),
    DependencyCall(
      id: "swiftdata",
      name: "SwiftData",
      verdict: .declined,
      reasoning: Bilingual(
        fr: """
          Il n'y a ici ni relation, ni requête, ni migration : une charge utile \
          par langue, écrite en entier, relue en entier. SwiftData apporterait \
          un modèle à décrire, un contexte à gérer et un schéma à faire évoluer \
          — pour remplacer `Data.write(to:)`.

          L'employer parce que c'est le framework moderne serait un choix \
          d'affichage, pas d'ingénierie. S'il fallait un jour chercher, trier ou \
          lier, la décision se reprendrait — et `LocalStore` est le protocole \
          qui la rendrait possible sans toucher au reste.
          """,
        en: """
          There is no relation here, no query, no migration: one payload per \
          language, written whole, read back whole. SwiftData would add a model \
          to describe, a context to manage and a schema to evolve — to replace \
          `Data.write(to:)`.

          Using it because it is the modern framework would be a display choice, \
          not an engineering one. If searching, sorting or relating were ever \
          needed, the decision would be revisited — and `LocalStore` is the \
          protocol that would make that possible without touching the rest.
          """
      )
    ),
  ]

  // ───────────────────────────────────────────────────────────────────────
  // The end-to-end walkthroughs
  // ───────────────────────────────────────────────────────────────────────

  public struct Walkthrough: Identifiable, Sendable, Hashable {
    public struct Step: Sendable, Hashable {
      public let actor: String
      public let does: Bilingual
    }

    public let id: String
    public let title: Bilingual
    public let summary: Bilingual
    public let steps: [Step]
  }

  public static let walkthroughs: [Walkthrough] = [
    Walkthrough(
      id: "resume",
      title: Bilingual(fr: "Ouvrir le CV en PDF", en: "Opening the PDF résumé"),
      summary: Bilingual(
        fr: "De la requête conditionnelle au nom de fichier que verra le destinataire.",
        en: "From the conditional request to the file name the recipient sees."
      ),
      steps: [
        .init(actor: "ResumeScreen", does: Bilingual(
          fr: "demande le document dans la langue courante — et ne sait rien de plus",
          en: "asks for the document in the current language — and knows nothing more")),
        .init(actor: "ResumeRepository", does: Bilingual(
          fr: "relit l'`ETag` déjà connu et joint `If-None-Match` à la requête",
          en: "reads back the known `ETag` and attaches `If-None-Match` to the request")),
        .init(actor: "URLSessionHTTPClient", does: Bilingual(
          fr: "télécharge **dans un fichier**, jamais en mémoire",
          en: "downloads **to a file**, never into memory")),
        .init(actor: "API", does: Bilingual(
          fr: "répond `304` — pas un octet de corps — ou `200` avec `Content-Disposition`",
          en: "answers `304` — not one byte of body — or `200` with `Content-Disposition`")),
        .init(actor: "ContentDisposition", does: Bilingual(
          fr: "lit le nom annoncé : `filename*` d'abord, `filename` ensuite, et refuse tout ce qui ressemble à un chemin",
          en: "reads the announced name: `filename*` first, `filename` next, and refuses anything resembling a path")),
        .init(actor: "ResumeRepository", does: Bilingual(
          fr: "déplace le fichier sous ce nom dans le cache, et enregistre l'`ETag`",
          en: "moves the file under that name into the cache, and stores the `ETag`")),
        .init(actor: "PDFView", does: Bilingual(
          fr: "ouvre l'URL et ne lit que les pages regardées",
          en: "opens the URL and reads only the pages being looked at")),
        .init(actor: "ShareLink", does: Bilingual(
          fr: "transmet l'URL — donc le **nom** — et non des octets anonymes",
          en: "passes the URL — hence the **name** — not anonymous bytes")),
      ]
    ),
    Walkthrough(
      id: "content",
      title: Bilingual(fr: "Afficher le contenu", en: "Showing the content"),
      summary: Bilingual(
        fr: "Trois couches, une seule requête, et l'aveu de ce qu'on montre.",
        en: "Three layers, one request, and an admission of what is on screen."
      ),
      steps: [
        .init(actor: "PortfolioStore", does: Bilingual(
          fr: "consomme un flux : il affiche le premier élément sans attendre le suivant",
          en: "consumes a stream: it shows the first element without waiting for the next")),
        .init(actor: "PortfolioRepository", does: Bilingual(
          fr: "rend d'abord le cache disque, sinon la graine embarquée",
          en: "yields the disk cache first, otherwise the bundled seed")),
        .init(actor: "PortfolioRepository", does: Bilingual(
          fr: "lance **une** requête réseau, partagée par tous les appelants simultanés",
          en: "starts **one** network request, shared by every simultaneous caller")),
        .init(actor: "JSONDecoder", does: Bilingual(
          fr: "décode — et son `codingPath` donne gratuitement le chemin du champ fautif",
          en: "decodes — and its `codingPath` hands you the faulty field's path for free")),
        .init(actor: "PortfolioMapper", does: Bilingual(
          fr: "valide ce que le domaine ne peut pas accepter : un rôle inconnu **lève**, il ne se replie pas",
          en: "validates what the domain cannot accept: an unknown role **throws**, it does not fall back")),
        .init(actor: "PortfolioRepository", does: Bilingual(
          fr: "écrit en cache les **octets reçus**, pas un ré-encodage — qui perdrait les champs pas encore lus",
          en: "caches the **bytes received**, not a re-encoding — which would drop fields not yet read")),
        .init(actor: "PortfolioStore", does: Bilingual(
          fr: "affiche le nouvel instantané, en disant d'où il vient",
          en: "shows the new snapshot, saying where it came from")),
      ]
    ),
  ]
}
