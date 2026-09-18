// swift-tools-version: 6.2
import PackageDescription

/// Le découpage en modules de l'application.
///
/// Chaque cible est une **unité de compilation**, et c'est le point : une
/// dépendance absente d'ici n'est pas une convention qu'on se promet de tenir,
/// c'est un `import` qui ne compile pas.
///
/// ```
///                    ┌──────────────────┐
///                    │  AppComposition  │  ← le seul qui connaisse tout le monde
///                    └────────┬─────────┘
///           ┌─────────────────┼──────────────────┐
///           ▼                 ▼                  ▼
///      Feature*            Data              Backstage
///           │            ┌───┴────┐              │
///           ▼            ▼        ▼              ▼
///      FeatureKit   Networking Persistence  DesignSystem
///           │                                    │
///           └──────────► Domain ◄────────────────┘
/// ```
///
/// **`Domain` ne dépend de rien.** Pas de `Networking`, pas de SwiftUI, pas même
/// d'un format de sérialisation. Il décrit ce que l'application *est* — des
/// entités et des ports — et les couches extérieures s'y branchent.
///
/// **Aucune fonctionnalité ne voit `Networking`, `Persistence` ni `Data`.** Une
/// vue parle à un port du `Domain` ; ce qui l'implémente est décidé dans
/// `AppComposition` et nulle part ailleurs. C'est l'inversion des dépendances
/// tenue par le compilateur plutôt que par la vigilance — et
/// `Tests/ArchitectureTests` échoue si le graphe dérive.
let package = Package(
  name: "AmissanKit",
  defaultLocalization: "fr",
  // iOS 18 est le plancher, pas la cible : l'application tourne en Liquid Glass
  // sur iOS 26 **et** sur le style natif d'iOS 18, sans deux bases de code.
  platforms: [.iOS(.v18)],
  products: [
    // Un seul produit exporté. L'application n'a aucune raison de pouvoir
    // importer `Networking` directement : lui en donner la possibilité, c'est
    // la lui voir prendre un jour où ça arrangeait.
    .library(name: "AppComposition", targets: ["AppComposition"]),
  ],
  dependencies: [
    // Lottie : des animations vectorielles que ni SwiftUI ni Core Animation ne
    // savent produire — des tracés dessinés hors de Xcode. Version épinglée au
    // mineur : la bibliothèque est mature et suit le semver.
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),

    // Textual : du Markdown rendu en `AttributedString` native. Le même auteur
    // maintenait MarkdownUI, aujourd'hui en mode maintenance et qui renvoie
    // explicitement ici.
    //
    // ⚠️ Version **0.x** : le semver ne promet rien avant la 1.0, une version
    // mineure a le droit de casser. D'où `upToNextMinor` et non `from` — on
    // choisit d'accepter les correctifs et de décider des montées de version.
    .package(url: "https://github.com/gonzalezreal/textual", .upToNextMinor(from: "0.5.0")),
  ],
  targets: [
    // ─────────────────────────────────────────────────────────────────────
    // Le cœur — il ne dépend de rien, et rien ne le fait dépendre de quelque
    // chose. C'est la seule couche qui survivrait à un changement complet de
    // transport, de stockage et d'interface.
    // ─────────────────────────────────────────────────────────────────────
    .target(name: "Domain"),

    // ─────────────────────────────────────────────────────────────────────
    // Les couches techniques — elles ne connaissent pas le domaine.
    //
    // `Networking` sait parler HTTP, pas ce qu'est un profil. C'est ce qui
    // permet de la tester sans rien savoir du portfolio, et de la remplacer
    // sans toucher au reste.
    // ─────────────────────────────────────────────────────────────────────
    .target(name: "Networking"),
    .target(name: "Persistence"),

    // Le seul endroit où le domaine et la technique se rencontrent : les
    // adaptateurs. Les DTO vivent ici, jamais dans `Domain` — une entité qui
    // porte des `CodingKeys` est une entité qui a laissé le réseau dicter sa
    // forme.
    .target(
      name: "Data",
      dependencies: ["Domain", "Networking", "Persistence"],
      // La graine embarquée — produite depuis l'API par `Scripts/seed.sh`.
      resources: [.process("Resources")]
    ),

    // ─────────────────────────────────────────────────────────────────────
    // La présentation
    // ─────────────────────────────────────────────────────────────────────
    .target(
      name: "DesignSystem",
      dependencies: [.product(name: "Lottie", package: "lottie-ios")],
      resources: [.process("Resources")]
    ),

    // Les « Coulisses » : le modèle des annotations et leur rendu. Séparé du
    // design system parce que c'est une **fonctionnalité de l'application**,
    // pas une primitive visuelle — et séparé des fonctionnalités parce que
    // toutes s'annotent.
    .target(
      name: "Backstage",
      dependencies: [
        // `Domain` pour `Language` et `Bilingual` : une annotation est du
        // contenu, et un contenu a une langue. La dépendance est gratuite —
        // `Domain` ne dépend lui-même de rien.
        "Domain",
        "DesignSystem",
        .product(name: "Textual", package: "textual"),
      ]
    ),

    // ─────────────────────────────────────────────────────────────────────
    // Les fonctionnalités
    //
    // Les cibles gardent leur nom — c'est lui qui apparaît dans les `import` et
    // dans les messages du compilateur. Leurs sources, elles, vivent sous
    // `Sources/Features/`, parce qu'une liste de treize répertoires à plat ne
    // dit plus rien de la forme du projet.
    //
    // Le `path:` explicite est ce qui permet de séparer les deux : le nom d'une
    // cible et l'endroit où elle vit n'ont aucune raison d'être le même mot.
    // ─────────────────────────────────────────────────────────────────────

    // Ce que toutes les fonctionnalités partagent : navigation, phases d'écran,
    // formatage. Il voit `Domain` — donc des ports — jamais `Data`.
    .target(
      name: "FeatureKit",
      dependencies: ["Domain", "DesignSystem", "Backstage"],
      path: "Sources/Features/Kit"
    ),

    .target(name: "FeatureProfile", dependencies: ["FeatureKit"], path: "Sources/Features/Profile"),
    .target(name: "FeatureWork", dependencies: ["FeatureKit"], path: "Sources/Features/Work"),
    .target(name: "FeatureJourney", dependencies: ["FeatureKit"], path: "Sources/Features/Journey"),
    .target(name: "FeatureResume", dependencies: ["FeatureKit"], path: "Sources/Features/Resume"),
    .target(name: "FeatureBackstage", dependencies: ["FeatureKit"], path: "Sources/Features/Backstage"),
    .target(name: "FeatureSettings", dependencies: ["FeatureKit"], path: "Sources/Features/Settings"),

    // ─────────────────────────────────────────────────────────────────────
    // La racine de composition — le seul module qui a le droit de tout voir,
    // parce que quelqu'un doit brancher les implémentations sur les ports.
    // ─────────────────────────────────────────────────────────────────────
    .target(
      name: "AppComposition",
      dependencies: [
        "Data",
        "FeatureProfile",
        "FeatureWork",
        "FeatureJourney",
        "FeatureResume",
        "FeatureBackstage",
        "FeatureSettings",
      ]
    ),

    // ─────────────────────────────────────────────────────────────────────
    // Tests
    // ─────────────────────────────────────────────────────────────────────
    .testTarget(name: "DomainTests", dependencies: ["Domain"]),
    .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
    .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),
    .testTarget(
      name: "DataTests",
      dependencies: ["Data"],
      resources: [.process("Fixtures")]
    ),
    .testTarget(name: "BackstageTests", dependencies: ["Backstage"]),
    .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),

    // Le graphe de dépendances est lui-même sous test : une fonctionnalité qui
    // se mettrait à importer `Networking` compilerait — c'est la *règle* qui
    // l'interdit, et une règle non exécutée finit contournée.
    //
    // Le manifeste n'est pas embarqué en ressource : SPM refuse une ressource
    // hors du répertoire de la cible, et la copier en ferait une seconde
    // version qui dériverait. Le test remonte jusqu'à lui depuis `#filePath`.
    .testTarget(name: "ArchitectureTests"),
  ],
  swiftLanguageModes: [.v6]
)
