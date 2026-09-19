import DesignSystem
import Presentation
import SwiftUI
import ViewKit

package extension View {
  /// Annotates this component: in decision mode it is outlined, and a pin opens
  /// its explanation.
  ///
  /// Outside decision mode the modifier **changes nothing** — not the layout,
  /// not accessibility, not the touch surface. A demonstration feature that
  /// degraded the ordinary app would be worth nothing.
  func decision(_ note: DesignDecision) -> some View {
    modifier(DecisionOverlay(note: note))
  }

  /// The same, for a call site that annotates one item of a list and not the
  /// others. `nil` annotates nothing and costs nothing.
  @ViewBuilder
  func decision(_ note: DesignDecision?) -> some View {
    if let note {
      modifier(DecisionOverlay(note: note))
    } else {
      self
    }
  }
}

/// The outline and the pin, **attached to the component they annotate**.
///
/// The name is the one the old machinery had, and it fits far better now: this
/// really is an overlay on the annotated view, where the previous `DecisionOverlay`
/// was a screen-wide layer that drew other views' business.
///
/// ## What this replaces, and why the replacement is smaller
///
/// It was an anchor preference. Every annotated view published its bounds up
/// the tree, a per-screen overlay collected them all, a `GeometryReader`
/// resolved each anchor against the screen, and the result was sorted, filtered
/// to what was visible, clipped to the viewport, and numbered.
///
/// All of that machinery existed to serve **one** feature: numbering the pins
/// in reading order, which needs to know where every annotation on the screen
/// is. And it produced, in order: numbering that changed as lazy rows recycled,
/// dashed frames left behind by views that had scrolled away, root-screen
/// annotations still counted two screens deep, and a full-screen rectangle
/// around any note attached to a scroll view.
///
/// The author's question was the right one: *why isn't each annotation a
/// modifier on the view it annotates?* Then there is nothing to compute. An
/// `overlay` is laid out in its content's bounds, so the outline **is** the
/// component's edge — it moves with it, it is clipped by whatever clips it, and
/// when the component is not rendered neither is it. Every one of those four
/// defects stops being possible rather than being fixed.
///
/// ## And the number went with it
///
/// Which was the second half of the same question. A pin's number said where it
/// sat in a reading order the reader can already see, and it was the only thing
/// that required the screen-wide view. What identifies a note is the component
/// it is on — `NavigationStack`, `LazyVGrid` — and that is what the sheet and
/// the accessibility label say.
private struct DecisionOverlay: ViewModifier {
  let note: DesignDecision

  @Environment(SettingsStore.self) private var settings
  @Environment(DecisionController.self) private var decision
  @ReducedMotion private var reducedMotion
  @Localized(.decisions) private var text

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .topTrailing) {
        if settings.showsDecisions {
          annotation
            .transition(.opacity)
        }
      }
      .animation(reducedMotion ? nil : Motion.toggle, value: settings.showsDecisions)
  }

  private var annotation: some View {
    ZStack(alignment: .topTrailing) {
      // The outline shows what is annotated. A pin on its own leaves you
      // guessing what it refers to — and a misplaced pin does not show at all,
      // which happened, and is what motivated drawing the edge in the first
      // place.
      RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
        .strokeBorder(
          Color.accent.opacity(Tokens.Opacity.annotation),
          style: StrokeStyle(lineWidth: Tokens.Stroke.regular, dash: [4, 3])
        )
        .allowsHitTesting(false)

      // ⚠️ **Inside** the corner it marks, not straddling it.
      //
      // Half outside reads better on a card in the middle of a page and is
      // wrong at the edges: a component flush with the screen has its pin
      // sliced in half by the window, and the first block of every screen is
      // flush with the screen.
      pin
    }
    .accessibilityHidden(!settings.showsDecisions)
  }

  private var pin: some View {
    Button {
      decision.present(note)
    } label: {
      // `.fill` through the symbol variant rather than by naming
      // "number.circle.fill": a screen asks `Icon` for a meaning and never
      // spells a glyph, and a misspelt SF Symbol renders nothing at all.
      Image(Icon.annotations)
        .symbolVariant(.fill)
        .font(.system(size: Tokens.Layout.decisionBadge, weight: .semibold))
        .symbolRenderingMode(.palette)
        .foregroundStyle(Color.onAccent, Color.accent)
        // A ring of paper, so the pin reads against whatever it lands on.
        .background(Circle().fill(Color.paper).padding(-Tokens.Stroke.regular))
    }
    // The glyph is 26 points across, the touch target 44: the rest is
    // transparent surface. A pin you have to aim at is a pin nobody taps.
    .frame(
      width: Tokens.Accessibility.minimumTouchTarget,
      height: Tokens.Accessibility.minimumTouchTarget
    )
    .contentShape(Circle())
    .accessibilityLabel(text(DecisionLabels.badge, note.component))
    .accessibilityHint(text(DecisionLabels.badgeHint))
  }
}
