import Domain
import Presentation
import SwiftUI
import TipKit

/// Points at the decision mode — **once**.
///
/// ## Why TipKit and not a custom bubble
///
/// A hand-rolled "did you know" needs somewhere to remember it was shown, a rule
/// for when it may appear, and a way to never come back. All three get written
/// badly the first time: the flag ends up in `UserDefaults` under a key nobody
/// documents, and the bubble reappears after a reinstall or, worse, on every
/// launch because the flag was written before the tip was actually read.
///
/// TipKit owns all of that, and it owns it *correctly*: the store is the
/// system's, `MaxDisplayCount` is a rule rather than a counter somebody
/// increments, and invalidating a tip because the reader already used the
/// feature is one line.
///
/// ## Why this app has exactly one tip
///
/// Because tips are a budget. Two of them and the reader starts dismissing
/// without reading, which spends the credibility of the one that mattered. This
/// is the only feature in the app that is genuinely invisible until somebody
/// points at it.
package struct DecisionsTip: Tip {
  /// The two sentences, already read from the catalogue.
  ///
  /// A `Tip` is not a `View`, so it cannot resolve a key itself — its members
  /// are nonisolated, and there is no environment to read. So the screen that
  /// presents it resolves them and hands them over, which keeps the rule intact:
  /// no type outside the view layer ever names a language.
  private let titleText: String
  private let messageText: String

  /// Shown once, and never again after the reader has turned the mode on.
  ///
  /// The rule is declarative: TipKit evaluates it, and nothing in the app has to
  /// remember to call `invalidate` from the right place.
  @Parameter package static var hasBeenUsed: Bool = false

  package init(title: String, message: String) {
    self.titleText = title
    self.messageText = message
  }

  package var rules: [Rule] {
    #Rule(Self.$hasBeenUsed) { $0 == false }
  }

  package var title: Text { Text(titleText) }

  package var message: Text? { Text(messageText) }

  package var image: Image? { Image(Icon.annotations) }
}

/// The tip's lifecycle, as two calls the composition root can make.
///
/// It exists so that `Composition` does not import TipKit. The root decides
/// *when* — at launch, and when the reader turns the mode on — and this decides
/// *what*, next to the tip it concerns. A root that had to know about
/// `Tips.configure()` would be a root that knows about a rendering framework.
public enum DecisionsTipState {
  /// Called once, at launch, before any tip can be evaluated.
  public static func configure() {
    try? Tips.configure()
  }

  /// The tip has done its job: the reader turned the mode on.
  ///
  /// The rule in `DecisionsTip` is declarative, so this is the only call needed
  /// — there is no "dismiss" to remember from three different places.
  public static func markUsed() {
    DecisionsTip.hasBeenUsed = true
  }
}
