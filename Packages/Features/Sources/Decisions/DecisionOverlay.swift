import DesignSystem
import Domain
import Localization
import Presentation
import SwiftUI
import ViewKit

/// The numbered pins, laid over the annotated components.
///
/// ## Why anchors, and not a `ZStack` per component
///
/// Putting the pin inside the annotated view would have forced every component
/// to reserve room for it — therefore to change layout depending on whether the
/// mode is on. Anchors leave the view **untouched** and draw on top, in a layer
/// that knows the geometry of the whole screen.
///
/// It is also what allows numbering **in reading order**: the pins are sorted by
/// vertical position, not by declaration order. Without that sort, a component
/// declared lower but displayed higher would carry a number that contradicts
/// what you read.
package struct DecisionOverlay: ViewModifier {
  @Environment(DecisionController.self) private var decision
  @Environment(SettingsStore.self) private var settings
  @ReducedMotion private var reducedMotion
  @Localized(.decisions) private var text

  public init() {}

  public func body(content: Content) -> some View {
    content
      .overlayPreferenceValue(DecisionPinsKey.self) { pins in
        GeometryReader { proxy in
          let ordered = pins
            .map { (pin: $0, rect: proxy[$0.anchor]) }
            .sorted { ($0.rect.minY, $0.rect.minX) < ($1.rect.minY, $1.rect.minX) }

          ForEach(Array(ordered.enumerated()), id: \.element.pin.note.id) { index, entry in
            // The **frame** first: it shows what is annotated. A pin on its
            // own leaves you guessing what it refers to, and a misplaced pin
            // does not show at all — which happened, and is what motivated this
            // rendering.
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
              .strokeBorder(Color.accent.opacity(Tokens.Opacity.annotation), style: StrokeStyle(lineWidth: Tokens.Stroke.regular, dash: [4, 3]))
              .frame(width: entry.rect.width, height: entry.rect.height)
              .position(x: entry.rect.midX, y: entry.rect.midY)
              .allowsHitTesting(false)

            badge(number: index + 1, note: entry.pin.note)
              .position(
                x: min(entry.rect.maxX - Tokens.Space.s2, proxy.size.width - Tokens.Space.s5),
                y: entry.rect.minY + Tokens.Space.s2
              )
          }
        }
        .allowsHitTesting(settings.showsDecisions)
        .opacity(settings.showsDecisions ? 1 : 0)
        .animation(reducedMotion ? nil : Motion.toggle, value: settings.showsDecisions)
      }
      .sheet(item: Binding(
        get: { decision.presented },
        set: { decision.presented = $0 }
      )) { note in
        DecisionSheet(note: note)
      }
  }

  private func badge(number: Int, note: DesignDecision) -> some View {
    Button {
      decision.present(note)
    } label: {
      Text("\(number)")
        .font(.system(size: Tokens.Icon.caption, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(Color.onAccent)
        .frame(width: Tokens.Layout.decisionPin, height: Tokens.Layout.decisionPin)
        .background(Circle().fill(Color.accent))
        .overlay(Circle().strokeBorder(Color.paper, lineWidth: Tokens.Stroke.regular * 2))
    }
    // The pin is 26 points across, the touch target 44: the rest is transparent
    // surface. A pin you have to aim at is a pin nobody taps.
    .frame(
      width: Tokens.Accessibility.minimumTouchTarget,
      height: Tokens.Accessibility.minimumTouchTarget
    )
    .contentShape(Circle())
    .accessibilityLabel(text(DecisionLabels.badge, number, note.component))
    .accessibilityHint(text(DecisionLabels.badgeHint))
  }
}

package extension View {
  /// Turns on the annotation layer for this screen.
  ///
  /// To be applied **once per screen**, at the topmost level: that is where the
  /// geometry of all the content is known.
  func decisionOverlay() -> some View {
    modifier(DecisionOverlay())
  }
}
