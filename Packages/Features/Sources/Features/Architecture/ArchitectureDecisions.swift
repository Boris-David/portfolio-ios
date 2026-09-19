import Decisions
import Foundation
import Localization

/// The design decisions annotated on the Architecture screens.
///
/// ## What a declaration says, and what it does not
///
/// It says **which** decision, on **which** component, and where Apple documents
/// it. Every sentence a reader sees lives in `Resources/Localizable.xcstrings`,
/// beside this file, keyed off the identifier: `<id>.role`, `<id>.rationale`,
/// `<id>.whenToUse`, `<id>.pitfall`, and `<id>.rejected.1.name` / `.because`.
///
/// So changing a piece of text never reopens a Swift file, let alone a `body`.
/// Adding a language adds a column to the catalogue and not one line of code.
enum ArchitectureDecisions {
  /// Still called `comparison` in the catalogue, and no longer a grid.
  static let comparison = DesignDecision(
    id: "architecture.comparison",
    component: "ScrollView(.horizontal) · contentTransition",
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)"),
    in: .architecture
  )
}

extension TextCatalogue {
  /// This feature's catalogue, read from this module's own bundle.
  ///
  /// One per screen module rather than one shared file: the text sits beside the
  /// code it belongs to, and a feature cannot silently depend on a sentence
  /// another feature owns.
  static let architecture = TextCatalogue(bundle: .module, table: "Localizable")
}
