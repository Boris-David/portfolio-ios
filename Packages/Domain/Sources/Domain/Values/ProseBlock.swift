/// A unit of written body, as the source publishes it.
///
/// Three shapes, and no more: a paragraph, a list, a set of technical chips.
/// The list is closed because a fourth would have to be drawn somewhere, and a
/// block nobody renders is a block that reaches a reader as nothing at all.
///
/// It lives at the top level rather than inside one type because two of them
/// carry prose now — a case study chapter and a deep dive — and the alternative
/// was `DeepDive.Section.blocks: [CaseStudy.Block]`, which would have said the
/// essay depends on the case study. It does not; they share a vocabulary.
public enum ProseBlock: Sendable, Hashable {
  case paragraph(RichText)
  case list([RichText])
  case tags([String])
}

public extension [ProseBlock] {
  /// The technical chips these blocks carry, in order.
  var tags: [String] {
    compactMap { if case .tags(let items) = $0 { items } else { nil } }.flatMap(\.self)
  }

  /// The written body, lists flattened: in a single column, a list and a run of
  /// paragraphs read the same.
  var prose: [RichText] {
    flatMap { block -> [RichText] in
      switch block {
      case .paragraph(let text): [text]
      case .list(let items): items
      case .tags: []
      }
    }
  }
}
