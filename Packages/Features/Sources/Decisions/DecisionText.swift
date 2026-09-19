import Domain
import SwiftUI
import ViewKit

/// A decision, with every sentence already read from its catalogue.
///
/// ## Why the sheet does not read them itself
///
/// It did, and it meant a view holding an `@Environment(\.contentLanguage)` and
/// threading it through five calls. Nothing was wrong with the result, and the
/// shape was wrong: a view that handles a language is a view that *could* branch
/// on one, and the rule is that none of them can.
///
/// So the language is read here, once, by a property wrapper — the same place
/// and the same way `@Localized` reads it for catalogue keys — and what reaches
/// the sheet is text. Adding a language changes nothing in any view, because no
/// view ever mentions one.
package struct DecisionText: Sendable {
  package let role: String
  package let rationale: String
  package let whenToUse: String
  package let pitfall: String?
  package let rejected: [DesignDecision.RejectedOption]
}

/// Reads a decision in the language currently on screen.
///
/// A `DynamicProperty` rather than a computed property on the view: this is what
/// makes the sheet re-read its text when the reader switches language, without
/// the view knowing that a language exists.
@propertyWrapper
package struct LocalizedDecision: DynamicProperty {
  @Environment(\.contentLanguage) private var language

  private let decision: DesignDecision

  package init(_ decision: DesignDecision) {
    self.decision = decision
  }

  package var wrappedValue: DecisionText {
    DecisionText(
      role: decision.role(language),
      rationale: decision.rationale(language),
      whenToUse: decision.whenToUse(language),
      pitfall: decision.pitfall(language),
      rejected: decision.rejected(language)
    )
  }
}
