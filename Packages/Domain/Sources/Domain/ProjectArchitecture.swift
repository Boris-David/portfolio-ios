/// A codebase, the pattern it follows, and the measurements that show it.
public struct ProjectArchitecture: Sendable, Hashable, Identifiable {
  public let id: String
  public let name: String
  public let context: String

  /// The pattern itself — **resolved**, never a reference to one.
  ///
  /// The source sends an identifier and writes each pattern's trade-offs once,
  /// so that no codebase can restate them and let one copy drift. The crossing
  /// from transport to domain follows that reference and refuses a dossier where
  /// it dangles.
  ///
  /// So the entity carries the pattern, not its name. A screen never holds a
  /// project whose pattern *might* be missing, and therefore never has to invent
  /// a fallback for a case the source already rules out: the invalid state stops
  /// being representable instead of being guarded at every point of reading.
  public let pattern: ArchitecturePattern

  public let stack: [String]
  /// What was counted in the files. Empty is a legitimate answer: a codebase can
  /// be described without a suffix worth counting in it.
  public let evidence: [ArchitectureEvidence]
  /// What the measurements add up to.
  public let reading: RichText

  public init(
    id: String,
    name: String,
    context: String,
    pattern: ArchitecturePattern,
    stack: [String],
    evidence: [ArchitectureEvidence],
    reading: RichText
  ) {
    self.id = id
    self.name = name
    self.context = context
    self.pattern = pattern
    self.stack = stack
    self.evidence = evidence
    self.reading = reading
  }
}
