/// Something the application presents **over** the whole scene, rather than
/// inside a section's stack.
///
/// ## Why one enum and not two
///
/// There used to be two — `Sheet` and `FullScreenCover` — on the argument that
/// two types make the wrong pairing unrepresentable: nobody could present a
/// résumé at a medium detent, because the résumé was not a `Sheet`.
///
/// The argument was true and the cost was higher than the benefit. Two enums
/// meant two resolvers, two environment actions and **two presentation anchors**
/// — and the day one anchor was written without re-applying the scene's
/// environment, the app was one tap away from *"No Observable object of type
/// SettingsStore found"*. That defect had already been paid for once on the
/// settings path; it was sitting latent on the contact path.
///
/// One enum restores the invariant somewhere stronger: a modal **declares its
/// own style**, so a caller still cannot ask for the résumé as a sheet — it does
/// not get to choose. And because there is now one anchor, forgetting the
/// environment on the second one is not a bug that can be written.
///
/// The invariant also became testable without a renderer, which "it does not
/// compile" never was: `#expect(Modal.resume.style == .fullScreen)` says *why*
/// the résumé is full-screen, where two types only said *that* it was.
public enum Modal: String, CaseIterable, Identifiable, Hashable, Sendable {
  /// One address and a short list of links.
  case contact
  /// Appearance, language, annotations.
  case settings
  /// The document itself.
  case resume

  public var id: String { rawValue }

  /// How the scene presents it — a property of **what it is**, never of who
  /// asked for it.
  ///
  /// A **sheet** keeps the screen underneath partly in view: it says "you have
  /// not left, this is a detour". A **cover** takes everything: it says "this is
  /// the task now, and you will come back deliberately". Reading a PDF is the
  /// immersive case — it is a document, it wants the width, and leaving it
  /// should be a decision rather than a stray downward swipe.
  public var style: Style {
    switch self {
    case .contact, .settings: .sheet
    case .resume: .fullScreen
    }
  }

  public enum Style: Sendable, Hashable {
    case sheet
    case fullScreen
  }
}
