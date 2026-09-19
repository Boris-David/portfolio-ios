import SwiftUI

public extension EnvironmentValues {
  /// The namespace the two halves of a zoom transition match across.
  ///
  /// ## Why it travels in the environment
  ///
  /// A zoom needs a **source** and a **destination** that name the same
  /// identity in the same namespace. Here the source is a card inside a feature
  /// module and the destination is resolved in the composition root — two
  /// modules that cannot see each other, by design.
  ///
  /// It was wired as a parameter once, and it did not work: `WorkScreen`
  /// declared a namespace and handed it to `CaseStudyCard`, which never read it,
  /// while the destination matched against a *different* namespace held by the
  /// scene. Two halves, two namespaces, and a transition that silently fell back
  /// to a slide — silently, because a zoom with only one half is not an error.
  ///
  /// The owner is now the one view that contains both: the section's stack.
  ///
  /// ## Why optional
  ///
  /// `Namespace.ID` has no public initialiser, so there is no value to default
  /// to. `nil` means "no stack around this view" — a preview, a test — and the
  /// modifiers below then do nothing, which is the correct behaviour rather
  /// than a crash.
  @Entry var zoomNamespace: Namespace.ID?
}

public extension View {
  /// Marks this view as the thing a pushed screen grows out of.
  ///
  /// The `id` has to be the same value the destination names — a slug, an
  /// identifier. Anything derived from layout position would stop matching the
  /// moment the list reorders.
  func zoomSource(_ id: some Hashable) -> some View {
    modifier(ZoomSourceModifier(id: AnyHashable(id)))
  }

  /// Marks this screen as what grew out of the source carrying the same `id`.
  func zoomDestination(_ id: some Hashable) -> some View {
    modifier(ZoomDestinationModifier(id: AnyHashable(id)))
  }
}

/// The half that stays behind.
private struct ZoomSourceModifier: ViewModifier {
  let id: AnyHashable
  @Environment(\.zoomNamespace) private var namespace

  func body(content: Content) -> some View {
    if let namespace {
      content.matchedTransitionSource(id: id, in: namespace)
    } else {
      content
    }
  }
}

/// The half that arrives.
private struct ZoomDestinationModifier: ViewModifier {
  let id: AnyHashable
  @Environment(\.zoomNamespace) private var namespace

  func body(content: Content) -> some View {
    if let namespace {
      content.navigationTransition(.zoom(sourceID: id, in: namespace))
    } else {
      content
    }
  }
}
