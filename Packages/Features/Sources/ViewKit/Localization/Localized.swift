import Domain
import Localization
import SwiftUI

/// The one place a key becomes text.
///
/// ## Why only here, and only in a view
///
/// Resolving a key is a **rendering** concern: it needs a bundle, a compiled
/// catalogue, and the language currently on screen. A presenter that returned a
/// finished sentence would have imported all three into a layer whose whole
/// value is being testable without any of them — so `Presentation` does not
/// declare `Localization`, and `import Localization` there answers "no such
/// module".
///
/// Everything below the view layer therefore deals in **values and keys**:
/// `ContentUnavailable` is a case, `MalformedReason` is a value, `AppSection`
/// hands back a `TextKey`. The sentence is assembled at the last possible
/// moment, by the thing that draws it.
///
/// ## Why the language comes from the environment
///
/// Because a view must not be able to name one. The language on screen is the
/// language of the **content** the API served, carried by `\.contentLanguage`,
/// and it is read here so that no screen ever gets the chance to branch on it.
/// Which languages exist is not stated in Swift at all: it is whatever the
/// compiled catalogue contains.
@propertyWrapper
package struct Localized: DynamicProperty {
  @Environment(\.contentLanguage) private var language

  private let catalogue: TextCatalogue

  package init(_ catalogue: TextCatalogue) {
    self.catalogue = catalogue
  }

  package var wrappedValue: LocalizedText {
    LocalizedText(catalogue: catalogue, language: language.rawValue)
  }
}
