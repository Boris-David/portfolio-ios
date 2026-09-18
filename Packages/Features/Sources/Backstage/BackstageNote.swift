import Domain
import Foundation

/// A backstage annotation: why **this** component, here.
///
/// This is the heart of the app. A portfolio that shows screens shows a result;
/// this one shows the **decisions** that led there — and a decision is judged by
/// what it ruled out as much as by what it kept.
///
/// The structure is not free-form, deliberately: every field is a question a
/// technical reviewer would ask anyway. An empty field shows, which is exactly
/// the point — a note that cannot say what it ruled out is not yet a decision,
/// it is a reflex.
package struct BackstageNote: Identifiable, Sendable, Hashable {
  /// What was considered, then ruled out.
  public struct Rejected: Sendable, Hashable {
    public let name: Bilingual
    /// The reason, in one sentence that stands on its own.
    public let because: Bilingual

    public init(_ name: Bilingual, because: Bilingual) {
      self.name = name
      self.because = because
    }
  }

  public let id: String
  /// The component used, under its exact name: `NavigationStack`, `Layout`,
  /// `matchedGeometryEffect`.
  public let component: String
  /// What it does **here**, in one sentence — not what it does in general.
  public let role: Bilingual
  /// Why this one. Markdown: the answer deserves more than a line.
  public let rationale: Bilingual
  /// The candidates ruled out. Empty only when there genuinely was no
  /// alternative — which is rare, and then it is worth saying.
  public let rejected: [Rejected]
  /// When to reach for it, in general. This is the part that is of use to
  /// somebody other than me.
  public let whenToUse: Bilingual
  /// The trap: what breaks, and what you only learn by walking into it.
  public let pitfall: Bilingual?
  /// Apple's documentation, where it exists.
  public let documentation: URL?

  public init(
    id: String,
    component: String,
    role: Bilingual,
    rationale: Bilingual,
    rejected: [Rejected] = [],
    whenToUse: Bilingual,
    pitfall: Bilingual? = nil,
    documentation: URL? = nil
  ) {
    self.id = id
    self.component = component
    self.role = role
    self.rationale = rationale
    self.rejected = rejected
    self.whenToUse = whenToUse
    self.pitfall = pitfall
    self.documentation = documentation
  }
}
