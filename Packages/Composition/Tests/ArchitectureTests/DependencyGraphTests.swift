import Foundation
import Testing

/// **The dependency graph is itself under test.**
///
/// "Screens do not know about the network" is a team rule, and team rules get
/// bent on a Friday evening. This one is held by the resolver — a screen that
/// writes `import Networking` gets "no such module", because `Features` never
/// declares that package.
///
/// So why a test at all? Because nothing stops someone **adding the line to the
/// manifest**, and then the resolver agrees. This suite reads every
/// `Package.swift` in the repository and refuses the edges that must not exist.
/// A rule no test executes is a rule that eventually gets worked around —
/// including this one.
struct DependencyGraphTests {
  // ───────────────────────────────────────────────────────────────────────
  // Reading the manifests
  //
  // They are read from the source tree rather than bundled as resources: SPM
  // refuses a resource outside its target's directory, and copying them would
  // create a second version that drifts. The walk starts at `#filePath`.
  // ───────────────────────────────────────────────────────────────────────

  private static let packagesDirectory: URL = {
    var url = URL(fileURLWithPath: #filePath)
    // …/Packages/Composition/Tests/ArchitectureTests/DependencyGraphTests.swift
    for _ in 0..<4 { url.deleteLastPathComponent() }
    return url
  }()

  private static let manifests: [String: String] = {
    let names = (try? FileManager.default.contentsOfDirectory(
      atPath: packagesDirectory.path
    )) ?? []
    var found: [String: String] = [:]
    for name in names where !name.hasPrefix(".") {
      let manifest = packagesDirectory
        .appendingPathComponent(name)
        .appendingPathComponent("Package.swift")
      if let text = try? String(contentsOf: manifest, encoding: .utf8) {
        found[name] = text
      }
    }
    return found
  }()

  /// The **package** dependencies a layer declares — the only doors it has.
  ///
  /// Read from `.package(path: "../X")`, which is what actually grants access.
  /// A target dependency inside a package is a separate question, tested below.
  private func packages(of layer: String) -> Set<String> {
    guard let manifest = Self.manifests[layer] else { return [] }
    let pattern = /\.package\(path: "\.\.\/([A-Za-z]+)"\)/
    return Set(manifest.matches(of: pattern).map { String($0.1) })
  }

  private static let layers = [
    "Domain", "Networking", "Persistence", "Data",
    "Presentation", "DesignSystem", "Features", "Composition",
  ]

  @Test("every layer is a package of its own")
  func everyLayerIsAPackage() {
    for layer in Self.layers {
      #expect(Self.manifests[layer] != nil, "\(layer)/Package.swift is missing")
    }
    #expect(
      Set(Self.manifests.keys) == Set(Self.layers),
      "a package appeared or disappeared without this test being told"
    )
  }

  // ───────────────────────────────────────────────────────────────────────
  // The invariants
  // ───────────────────────────────────────────────────────────────────────

  /// `Domain` describes what the application **is**. One dependency is enough to
  /// tie it to a platform detail, and then it is over.
  @Test("the domain depends on nothing at all")
  func domainDependsOnNothing() {
    #expect(packages(of: "Domain").isEmpty)
    #expect(Self.manifests["Domain"]?.contains("dependencies: []") == true)
  }

  /// `Networking` speaks HTTP, not portfolio. `Persistence` writes bytes, not
  /// entities. That is what lets each be tested knowing nothing of the other.
  @Test("the technical layers ignore the domain", arguments: ["Networking", "Persistence"])
  func infrastructureIgnoresDomain(_ layer: String) {
    #expect(packages(of: layer).isEmpty)
  }

  /// **The central invariant.** A screen talks to a port; what implements it is
  /// decided in `Composition` and nowhere else.
  @Test("no screen can reach the network, the disk, or the data layer")
  func featuresSeeNoInfrastructure() {
    let forbidden: Set<String> = ["Networking", "Persistence", "Data"]
    let leaked = packages(of: "Features").intersection(forbidden)
    #expect(
      leaked.isEmpty,
      "Features declares \(leaked.sorted().joined(separator: ", ")) — dependency inversion is broken"
    )
  }

  /// The presentation layer is the one that has to stay renderer-free. It sees
  /// the domain, and that is all: a presenter that can name a colour has started
  /// designing, and one that can name a view cannot be tested without a screen.
  @Test("the presentation layer sees the domain and nothing else")
  func presentationSeesOnlyDomain() {
    #expect(packages(of: "Presentation") == ["Domain"])
  }

  /// The design system must never learn what a profile is. It is a package of
  /// its own precisely so that `import Domain` cannot resolve there.
  @Test("the design system knows nothing of the domain")
  func designSystemIsIndependent() {
    #expect(packages(of: "DesignSystem").isEmpty)
    #expect(Self.manifests["DesignSystem"]?.contains("lottie-ios") == true)
  }

  /// `Data` is the only place where the domain and the plumbing meet — which is
  /// the whole reason it is allowed to name all three.
  @Test("the data layer is the only one that sees both sides")
  func dataIsTheOnlyMeetingPoint() {
    #expect(packages(of: "Data") == ["Domain", "Networking", "Persistence"])
    for layer in Self.layers where layer != "Data" && layer != "Composition" {
      let both = packages(of: layer).intersection(["Networking", "Persistence"])
      #expect(both.isEmpty, "\(layer) also reaches the plumbing")
    }
  }

  /// Someone has to wire ports to implementations. The discipline is that there
  /// is **exactly one** such package.
  @Test("only the composition root sees everything")
  func compositionIsTheOnlyRoot() {
    let composition = packages(of: "Composition")
    #expect(composition.contains("Data"))
    #expect(composition.contains("Features"))
    #expect(composition.contains("Presentation"))
  }

  // ───────────────────────────────────────────────────────────────────────
  // Inside the features package, where targets — not packages — are the border
  // ───────────────────────────────────────────────────────────────────────

  private static let screens = [
    "FeatureProfile", "FeatureWork", "FeatureJourney",
    "FeatureResume", "FeatureBackstage", "FeatureContact",
  ]

  /// Two screens that know each other stop being deliverable apart. They go
  /// through `FeatureKit` and through injected route resolution.
  @Test("no screen imports another screen")
  func screensDoNotKnowEachOther() {
    guard let manifest = Self.manifests["Features"] else { return }
    for screen in Self.screens {
      guard let declaration = manifest.range(of: ".target(name: \"\(screen)\"") else {
        Issue.record("\(screen) is not declared in Features/Package.swift")
        continue
      }
      let line = manifest[declaration.lowerBound...].prefix(while: { $0 != "\n" })
      let siblings = Self.screens.filter { $0 != screen && line.contains("\"\($0)\"") }
      #expect(siblings.isEmpty, "\(screen) depends on \(siblings.joined(separator: ", "))")
    }
  }

  /// The shared modules form a straight line — `ViewKit`, then `Backstage`,
  /// then `FeatureKit` — and a screen only ever mounts on the last of them.
  @Test("every screen is mounted on FeatureKit alone")
  func screensDependOnFeatureKit() {
    guard let manifest = Self.manifests["Features"] else { return }
    for screen in Self.screens {
      #expect(
        manifest.contains(".target(name: \"\(screen)\", dependencies: [\"FeatureKit\"]"),
        "\(screen) should declare FeatureKit and nothing else"
      )
    }
  }
}
