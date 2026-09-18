import Foundation
import Testing

/// **Le graphe de dépendances est lui-même sous test.**
///
/// « Les vues ne connaissent pas le réseau » est une règle d'équipe, et les
/// règles d'équipe se contournent le vendredi soir. Celle-ci est tenue par le
/// compilateur — un `import Networking` dans une fonctionnalité ne compile pas —
/// mais rien n'empêcherait quelqu'un d'**ajouter la dépendance au manifeste**,
/// et le compilateur serait alors d'accord.
///
/// Ce fichier est la garde de dernier recours : il lit `Package.swift` et refuse
/// les arêtes interdites. Une règle qu'aucun test n'exécute finit contournée —
/// y compris celle-là.
struct DependencyGraphTests {
  /// Le manifeste est lu depuis l'arborescence des sources, et non embarqué en
  /// ressource : SPM refuse une ressource hors du répertoire de la cible, et
  /// la copier en ferait une seconde version qui dériverait.
  private static let manifest: String = {
    var url = URL(fileURLWithPath: #filePath)
    for _ in 0..<3 { url.deleteLastPathComponent() }
    return (try? String(contentsOf: url.appendingPathComponent("Package.swift"), encoding: .utf8)) ?? ""
  }()

  /// Les dépendances déclarées d'une cible, telles qu'écrites dans le manifeste.
  private func dependencies(of target: String) -> Set<String> {
    let source = Self.manifest
    guard let start = source.range(of: "name: \"\(target)\"") else { return [] }

    // On lit jusqu'à la fermeture de la déclaration de cible : la prochaine
    // ligne qui commence une nouvelle `.target(` ou `.testTarget(`.
    let rest = source[start.upperBound...]
    let end = rest.range(of: "\n    .t") ?? rest.range(of: "\n  ]")
    let block = String(rest[..<(end?.lowerBound ?? rest.endIndex)])

    var found: Set<String> = []
    for name in Self.allTargets where block.contains("\"\(name)\"") {
      found.insert(name)
    }
    return found
  }

  private static let allTargets = [
    "Domain", "Networking", "Persistence", "Data", "DesignSystem", "Backstage",
    "FeatureKit", "FeatureProfile", "FeatureWork", "FeatureJourney",
    "FeatureResume", "FeatureBackstage", "AppComposition",
  ]

  private static let features = [
    "FeatureKit", "FeatureProfile", "FeatureWork", "FeatureJourney",
    "FeatureResume", "FeatureBackstage",
  ]

  @Test("le manifeste est lisible depuis les tests")
  func manifestIsReadable() {
    #expect(Self.manifest.contains("name: \"AmissanKit\""), "Package.swift introuvable depuis #filePath")
  }

  /// `Domain` décrit ce que l'application **est**. Une seule dépendance suffit à
  /// le faire dépendre d'un détail de plateforme, et c'est fini.
  @Test("Domain ne dépend d'aucun autre module")
  func domainDependsOnNothing() {
    #expect(dependencies(of: "Domain").isEmpty)
  }

  /// `Networking` sait parler HTTP, pas ce qu'est un profil. C'est ce qui permet
  /// de le tester sans rien savoir du domaine.
  @Test("les couches techniques ignorent le domaine", arguments: ["Networking", "Persistence"])
  func infrastructureIgnoresDomain(_ target: String) {
    #expect(dependencies(of: target).isEmpty)
  }

  /// **L'invariant central.** Une vue parle à un port du domaine ; ce qui
  /// l'implémente est décidé dans `AppComposition` et nulle part ailleurs.
  @Test("aucune fonctionnalité ne voit le réseau, le stockage ni les dépôts")
  func featuresSeeNoInfrastructure() {
    let forbidden: Set<String> = ["Networking", "Persistence", "Data"]
    for feature in Self.features {
      let leaked = dependencies(of: feature).intersection(forbidden)
      #expect(
        leaked.isEmpty,
        "\(feature) dépend de \(leaked.sorted().joined(separator: ", ")) — l'inversion de dépendances est rompue"
      )
    }
  }

  /// Deux fonctionnalités qui se connaissent finissent par ne plus pouvoir être
  /// livrées séparément. Elles passent par `FeatureKit` et par la résolution de
  /// routes injectée.
  @Test("aucune fonctionnalité n'en importe une autre")
  func featuresDoNotKnowEachOther() {
    let screens = Self.features.filter { $0 != "FeatureKit" }
    for feature in screens {
      let siblings = dependencies(of: feature).intersection(Set(screens)).subtracting([feature])
      #expect(siblings.isEmpty, "\(feature) dépend de \(siblings.sorted().joined(separator: ", "))")
    }
  }

  /// Le design system doit rester réutilisable dans une autre application. Le
  /// jour où il connaît `Portfolio`, il ne l'est plus.
  @Test("DesignSystem ne connaît pas le domaine")
  func designSystemIgnoresDomain() {
    #expect(!dependencies(of: "DesignSystem").contains("Domain"))
  }

  /// `Data` est le seul endroit où le domaine et la technique se rencontrent.
  @Test("Data est le seul adaptateur")
  func dataIsTheAdapter() {
    #expect(dependencies(of: "Data") == ["Domain", "Networking", "Persistence"])
  }

  /// Un seul produit exporté : l'application n'a aucune raison de pouvoir
  /// importer `Networking` directement.
  @Test("le paquet n'exporte que la racine de composition")
  func singleProduct() {
    let products = Self.manifest.components(separatedBy: ".library(name: \"").dropFirst()
    #expect(products.count == 1)
    #expect(products.first?.hasPrefix("AppComposition") == true)
  }
}
