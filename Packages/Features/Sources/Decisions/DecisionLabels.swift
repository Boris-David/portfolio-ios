import Localization
import ViewKit

/// The keys for the labels this module draws around a decision.
///
/// They live here, with the module that displays them, and not with the shared
/// interface catalogue: `Decisions` sits **below** the screens in the graph, and
/// a layer does not read the constants of the one that consumes it.
///
/// Every value behind these keys is in `Resources/Localizable.xcstrings`, beside
/// this file.
enum DecisionLabels {
  static let why: TextKey = "decision.section.why"
  static let rejected: TextKey = "decision.section.rejected"
  static let whenToUse: TextKey = "decision.section.whenToUse"
  static let pitfall: TextKey = "decision.section.pitfall"
  static let documentation: TextKey = "decision.action.documentation"
  static let close: TextKey = "decision.action.close"
  static let learnMore: TextKey = "decision.action.learnMore"
  static let learnMoreHint: TextKey = "decision.action.learnMore.hint"
  static let badgeHint: TextKey = "decision.badge.hint"

  /// "Decision: NavigationStack" — the pin's accessibility label.
  ///
  /// It carried an ordinal, and the ordinal is gone: it said where a pin sat
  /// in a reading order the reader can already see, and it was the only thing
  /// that required knowing where every other annotation on the screen was.
  ///
  /// The order of the two values belongs to the catalogue, not to this file: a
  /// language that needs the component first says `%2$@ %1$lld` and no Swift
  /// changes.
  static let badge: TextKey = "decision.badge.label"
}

extension TextCatalogue {
  /// This module's own catalogue, read from its own bundle.
  static let decisions = TextCatalogue(bundle: .module, table: "Localizable")
}
