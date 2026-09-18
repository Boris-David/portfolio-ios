/// What takes the whole screen.
///
/// ## Why this is a separate enum from `Sheet`
///
/// Because they are not the same promise. A **sheet** keeps the screen
/// underneath partly in view: it says "you have not left, this is a detour". A
/// **full-screen cover** takes everything: it says "this is the task now, and
/// you will come back deliberately".
///
/// Putting both in one enum would let a caller present a résumé at a medium
/// detent, or a contact card full-screen, with nothing to stop it. Two types
/// make the wrong one unrepresentable — which is the same reason `ViewPhase`
/// has four cases and not a pile of booleans.
///
/// Reading a PDF is the immersive case: it is a document, it wants the width,
/// and dismissing it is a decision rather than a stray downward swipe.
public enum FullScreenCover: Identifiable, Hashable, Sendable {
  case resume

  public var id: Self { self }
}
