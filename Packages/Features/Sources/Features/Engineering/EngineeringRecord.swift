import Localization
import ViewKit

/// What this app says about itself: its layers, the problems it solved, the way
/// a request travels through it, and every dependency call it made.
///
/// ## Why this content is not in the API
///
/// The test is the same as for the website: *content is what would still be true
/// if this client did not exist.* A fact about a career stays true without the
/// app, so it goes to the API. "Why an actor rather than a lock in **this** app"
/// means nothing without it: that is architecture documentation, it lives with
/// the code it describes, and it becomes wrong in the same commit.
///
/// ## What is declared here, and what is not
///
/// Identities, technical names, and the shape of the graph. Every **sentence**
/// lives in `Resources/Localizable.xcstrings` beside this file, keyed off the
/// identity -- so correcting a wording never reopens this file, and a third
/// language is one more column rather than a type with one more case.
package enum EngineeringRecord {
  // ---------------------------------------------------------------------
  // The layers
  // ---------------------------------------------------------------------

  /// One layer of the graph, as the app describes itself.
  ///
  /// `dependsOn` is not prose: the screen draws the arrows from it, and
  /// `FeatureEngineeringTests` reads the real manifests to compare them with
  /// this list. A layer that lies here is caught by the suite rather than by a
  /// reader.
  ///
  /// That test was written because this list **had** lied: it named
  /// `Persistence` and `Composition`, two modules that never existed under
  /// those names, and omitted `Core`, `CoreUI` and `Localization`. A second
  /// hand-maintained copy of the package graph drifts the day a package is
  /// renamed — and an architecture screen is the worst place in the app to be
  /// wrong.
  package struct Layer: Identifiable, Sendable, Hashable {
    package let id: String
    /// The module's real name, not translated: `Domain` is called `Domain` in
    /// every language.
    package let name: String
    package let dependsOn: [String]

    /// What it is responsible for, in one sentence.
    package var responsibilityKey: TextKey { TextKey("layer.\(id).responsibility") }
    /// The rule that keeps it honest.
    package var ruleKey: TextKey { TextKey("layer.\(id).rule") }
  }

  /// Listed leaves first: a layer only ever appears after everything it names.
  /// The order is the reading order of the graph, not an opinion about it.
  package static let layers: [Layer] = [
    Layer(id: "domain", name: "Domain", dependsOn: []),
    Layer(id: "networking", name: "Networking", dependsOn: []),
    Layer(id: "core", name: "Core", dependsOn: []),
    Layer(id: "localization", name: "Localization", dependsOn: []),
    Layer(id: "designsystem", name: "DesignSystem", dependsOn: []),
    Layer(id: "data", name: "Data", dependsOn: ["Core", "Domain", "Networking"]),
    Layer(id: "presentation", name: "Presentation", dependsOn: ["Domain"]),
    Layer(id: "coreui", name: "CoreUI", dependsOn: ["DesignSystem"]),
    Layer(
      id: "features",
      name: "Features",
      dependsOn: ["CoreUI", "DesignSystem", "Domain", "Localization", "Presentation"]
    ),
    Layer(
      id: "app",
      name: "Amissan",
      dependsOn: [
        "Core", "CoreUI", "Data", "DesignSystem", "Domain",
        "Features", "Localization", "Networking", "Presentation",
      ]
    ),
  ]

  // ---------------------------------------------------------------------
  // The problems solved
  // ---------------------------------------------------------------------

  /// A problem, what was done about it, and what it taught.
  ///
  /// The lesson is the part worth anything to somebody else, which is why it is
  /// a field rather than an afterthought.
  package struct Challenge: Identifiable, Sendable, Hashable {
    package let id: String

    package var titleKey: TextKey { TextKey("challenge.\(id).title") }
    package var problemKey: TextKey { TextKey("challenge.\(id).problem") }
    package var solutionKey: TextKey { TextKey("challenge.\(id).solution") }
    package var lessonKey: TextKey { TextKey("challenge.\(id).lesson") }
  }

  package static let challenges: [Challenge] = [
    Challenge(id: "coalescing"),
    Challenge(id: "offline"),
    Challenge(id: "compat"),
    Challenge(id: "boundaries"),
  ]

  // ---------------------------------------------------------------------
  // The dependency calls
  // ---------------------------------------------------------------------

  /// A judgement made about one library: taken, or turned down.
  ///
  /// Named a *decision* and not a *call*, because this repository also ships
  /// `HTTPClient` and `HTTPRequest`, where "call" means a function or a network
  /// round trip. One word with two meanings, in a file a reviewer reads once.
  package struct DependencyDecision: Identifiable, Sendable, Hashable {
    package let id: String
    /// The library's own name.
    package let name: String
    package let outcome: Outcome

    package var reasoningKey: TextKey { TextKey("dependency.\(id).reasoning") }

    /// Taken, at a version, or turned down. Not a "verdict": nobody was on
    /// trial, and a courtroom metaphor is the register this app just dropped.
    package enum Outcome: Sendable, Hashable {
      case adopted(version: String)
      case declined
    }
  }

  /// The rule, once and for all: *a dependency is justified by what would be
  /// worse without it, not by what it makes convenient.*
  package static let dependencies: [DependencyDecision] = [
    DependencyDecision(id: "lottie", name: "Lottie", outcome: .adopted(version: "4.6.x")),
    DependencyDecision(id: "alamofire", name: "Alamofire", outcome: .declined),
    DependencyDecision(id: "textual", name: "Textual", outcome: .adopted(version: "0.5.x")),
    DependencyDecision(id: "swiftdata", name: "SwiftData", outcome: .declined),
  ]

  // ---------------------------------------------------------------------
  // How a request travels
  // ---------------------------------------------------------------------

  /// One path through the app, step by step.
  package struct Walkthrough: Identifiable, Sendable, Hashable {
    package let id: String

    /// The type at each step, in order: `ResumeScreen`, `ResumeRepository`, and
    /// so on.
    ///
    /// These were called `actor` until 2026-09-18, in a Swift 6 codebase whose
    /// `Core` layer ships real actors. A reviewer scanning for concurrency stops
    /// on that; they are type names, so `component` it is.
    package let components: [String]

    package var titleKey: TextKey { TextKey("walkthrough.\(id).title") }
    package var summaryKey: TextKey { TextKey("walkthrough.\(id).summary") }

    /// What the component at `index` does. One-based, matching the catalogue.
    package func stepKey(_ index: Int) -> TextKey {
      TextKey("walkthrough.\(id).step.\(index).does")
    }
  }

  package static let walkthroughs: [Walkthrough] = [
    Walkthrough(id: "resume", components: ["ResumeScreen", "ResumeRepository", "URLSessionHTTPClient", "API", "ContentDisposition", "ResumeRepository", "PDFPreview", "ShareLink"]),
    Walkthrough(id: "content", components: ["PortfolioStore", "PortfolioRepository", "PortfolioRepository", "JSONDecoder", "PortfolioMapper", "PortfolioRepository", "PortfolioStore"]),
  ]
}

extension TextCatalogue {
  /// This feature's catalogue: everything the app says about how it is built.
  static let engineering = TextCatalogue(bundle: .module, table: "Localizable")
}
