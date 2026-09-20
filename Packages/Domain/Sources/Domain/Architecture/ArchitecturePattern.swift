/// A pattern, and what it separates, buys, costs, and where it breaks.
///
/// Every field is a cell of the comparison, and every pattern fills every one of
/// them. That is what makes the comparison a comparison rather than four
/// paragraphs standing side by side — and why `buys` and `costs` are a pair: a
/// pattern described only by what it buys is an advert, and nobody picks an
/// architecture from an advert.
public struct ArchitecturePattern: Sendable, Hashable, Identifiable {
  /// The patterns the comparison has a column for.
  ///
  /// A **closed** set, and deliberately so: the comparison is a table with one
  /// column per pattern. An open identifier would let a fifth one arrive with
  /// no cell to put it in, and the column would go missing without anything
  /// saying so.
  public enum Identifier: String, Sendable, Hashable {
    case mvc
    case mvp
    case mvvm
    case clean
  }

  /// The four questions every pattern is made to answer.
  ///
  /// They are part of what the comparison **means**, not of how it is drawn:
  /// dropping one would not change the layout, it would change the claim. The
  /// screen therefore walks this list instead of writing four rows by hand — a
  /// question added here appears in every column at once, and no pattern can
  /// quietly skip one.
  public enum Criterion: Sendable, Hashable, CaseIterable {
    case buys
    case costs
    case chooseWhen
    case breaksWhen
  }

  public let id: Identifier
  public let name: String
  /// What it pulls apart, in one sentence. The headline of the column: it is
  /// read before the reader decides whether to read the rest.
  public let separates: String
  public let buys: RichText
  public let costs: RichText
  public let chooseWhen: RichText
  public let breaksWhen: RichText

  public init(
    id: Identifier,
    name: String,
    separates: String,
    buys: RichText,
    costs: RichText,
    chooseWhen: RichText,
    breaksWhen: RichText
  ) {
    self.id = id
    self.name = name
    self.separates = separates
    self.buys = buys
    self.costs = costs
    self.chooseWhen = chooseWhen
    self.breaksWhen = breaksWhen
  }

  /// The answer this pattern gives to one of the comparison's questions.
  public func answer(to criterion: Criterion) -> RichText {
    switch criterion {
    case .buys: buys
    case .costs: costs
    case .chooseWhen: chooseWhen
    case .breaksWhen: breaksWhen
    }
  }
}
