import Domain
import Foundation
import Localization
import ViewKit

/// A decision annotation: why **this** component, here.
///
/// This is the heart of the app. A portfolio that shows screens shows a result;
/// this one shows the **decisions** that led there — and a decision is judged by
/// what it ruled out as much as by what it kept.
///
/// ## What a note declares, and what it does not
///
/// It declares an identity and a component. Everything a reader sees lives in
/// the feature's string catalogue, keyed off that identity: `\(id).role`,
/// `\(id).rationale`, `\(id).whenToUse`, `\(id).pitfall`, and
/// `\(id).rejected.1.name` / `.because` for each candidate ruled out.
///
/// So the catalogue decides what a note *contains*: a note without a pitfall
/// simply has no `…pitfall` entry. A parallel set of Swift flags could have
/// disagreed with the catalogue; this cannot.
///
/// The structure is not free-form, deliberately: every field is a question a
/// technical reviewer would ask anyway. A missing one shows, which is the point
/// — a note that cannot say what it ruled out is not yet a decision, it is a
/// reflex.
package struct DesignDecision: Identifiable, Sendable {
  /// What was considered, then ruled out.
  package struct RejectedOption: Sendable, Hashable, Identifiable {
    package let id: Int
    package let name: String
    /// The reason, in one sentence that stands on its own.
    package let because: String
  }

  /// The note's identity, and the prefix of every key it reads.
  package let id: String

  /// The component used, under its exact name: `NavigationStack`, `Layout`,
  /// `matchedGeometryEffect`. It is an API name, identical in every language,
  /// so it is the one string a note carries in Swift.
  package let component: String

  /// Apple's documentation, where it exists.
  package let documentation: URL?

  /// The feature's own catalogue. Each screen module carries one, beside its
  /// code — so a note is read from the bundle of the feature that declares it,
  /// whichever module ends up rendering it.
  private let catalogue: TextCatalogue

  package init(
    id: String,
    component: String,
    documentation: URL? = nil,
    in catalogue: TextCatalogue
  ) {
    self.id = id
    self.component = component
    self.documentation = documentation
    self.catalogue = catalogue
  }

  /// What it does **here**, in one sentence — not what it does in general.
  package func role(_ language: Language) -> String { text(language)(key("role")) }

  /// Why this one. Markdown: the answer deserves more than a line.
  package func rationale(_ language: Language) -> String { text(language)(key("rationale")) }

  /// When to reach for it, in general. This is the part that is of use to
  /// somebody other than the author.
  package func whenToUse(_ language: Language) -> String { text(language)(key("whenToUse")) }

  /// The trap: what breaks, and what you only learn by walking into it.
  /// Absent when the catalogue carries no entry for it.
  package func pitfall(_ language: Language) -> String? {
    let wording = text(language)
    let pitfall = key("pitfall")
    return wording.has(pitfall) ? wording(pitfall) : nil
  }

  /// The candidates ruled out, read until the catalogue stops offering one.
  ///
  /// The count is not declared in Swift: a second source for it would have been
  /// free to disagree. A gap in the numbering would leave later entries unread,
  /// which is why `check-strings.sh` fails on a key nothing reaches.
  package func rejected(_ language: Language) -> [RejectedOption] {
    let wording = text(language)
    var found: [RejectedOption] = []
    for index in 1...Self.mostRejectedCandidates {
      let name = key("rejected.\(index).name")
      guard wording.has(name) else { break }
      found.append(
        RejectedOption(id: index, name: wording(name), because: wording(key("rejected.\(index).because")))
      )
    }
    return found
  }

  /// A bound, so a malformed catalogue cannot spin. Well past the largest note.
  private static let mostRejectedCandidates = 12

  private func key(_ field: String) -> TextKey { TextKey("\(id).\(field)") }

  private func text(_ language: Language) -> LocalizedText {
    LocalizedText(catalogue: catalogue, language: language.rawValue)
  }
}

extension DesignDecision: Hashable {
  /// Identity is the id. The rest is read from a catalogue, and two notes with
  /// the same id would read the same text.
  package static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
  package func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
