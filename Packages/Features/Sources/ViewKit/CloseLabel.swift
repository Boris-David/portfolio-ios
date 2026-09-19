import DesignSystem
import Presentation
import SwiftUI

/// What the control that dismisses a presented screen says — or draws.
///
/// A `Label` and not a `Button`: the word is view work and belongs with the
/// catalogue, while *what closing means* belongs to whoever presented the
/// screen. The composition root can then write a close button without resolving
/// a single string — which `check-layers.sh` requires of it.
public struct CloseLabel: View {
  /// ## Why a sheet full of reading closes with a cross
  ///
  /// A word is the right affordance for a short task you finish — the settings
  /// form, the contact card: you read "Fermer" once, at the end. A reading you
  /// scroll is different: the control is in view the whole time, and a cross is
  /// what iOS puts on a presentation you leave rather than complete. It is also
  /// what tells the reader, at a glance, that this is a **modal** and not one
  /// more screen pushed onto a stack.
  public enum Form: Sendable {
    /// "Close". For a short task with an end.
    case word
    /// ✕. For a presentation the reader leaves whenever they like.
    case mark
  }

  private let form: Form

  @Localized(.interface) private var text

  public init(_ form: Form = .word) {
    self.form = form
  }

  public var body: some View {
    switch form {
    case .word:
      Text(text(InterfaceText.close))
    case .mark:
      // The glyph carries no word, so it carries the word for VoiceOver — a
      // control announced as "button" and nothing else is a control nobody
      // reaches without sight.
      Image(Icon.close)
        .font(.body.weight(.semibold))
        .accessibilityLabel(text(InterfaceText.close))
    }
  }
}
