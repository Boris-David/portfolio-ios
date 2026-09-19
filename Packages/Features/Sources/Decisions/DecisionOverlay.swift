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
/// ## Why it draws pins and does not present anything
///
/// It used to carry the `.sheet` as well, bound to the shared controller. There
/// is one overlay per tab shell plus one per presented screen, so **five sheets
/// were bound to one piece of state**, and SwiftUI picked. The report from the
/// device was exact: the annotations only ever appeared on the settings screen,
/// and a pin tapped anywhere else did nothing until Settings was opened — at
/// which point the note it had been holding appeared there.
///
/// That is the same defect that `Sheet` and `FullScreenCover` had, fixed one
/// change earlier and left standing here. The presentation moved to
/// `.decisionSheet(isEnabled:)`, applied by whoever owns a presentation
/// context — see that modifier.
package struct DecisionOverlay: ViewModifier {
  @Environment(SettingsStore.self) private var settings
  @Environment(DecisionController.self) private var decision
  @ReducedMotion private var reducedMotion
  @Localized(.decisions) private var text

  /// The number each note has been given, kept for as long as it stays on
  /// screen. See `DecisionNumbering` — that is the whole of the second bug,
  /// and it is a value so that it can be tested without a simulator.
  @State private var numbering = DecisionNumbering()

  public init() {}

  public func body(content: Content) -> some View {
    content
      .overlayPreferenceValue(DecisionPinsKey.self) { pins in
        GeometryReader { proxy in
          // ⚠️ Only what is actually on this screen.
          //
          // The overlay wraps the whole section — the stack and everything it
          // pushes — and a `NavigationStack` keeps its root alive underneath a
          // pushed screen. So the root's annotations stayed in the collected
          // set while the reader was two screens deep: they were numbered, they
          // drew dashed frames at meaningless coordinates, and a case study
          // opened with its first pin reading **3**.
          //
          // An annotation nobody can see is not an annotation. A rect with no
          // area is the same thing one step further: a component that has not
          // been laid out yet.
          let bounds = CGRect(origin: .zero, size: proxy.size)
          let ordered = pins
            .map { (pin: $0, rect: proxy[$0.anchor]) }
            .filter { !$0.rect.isEmpty && bounds.intersects($0.rect) }
            .sorted { ($0.rect.minY, $0.rect.minX) < ($1.rect.minY, $1.rect.minX) }

          ZStack(alignment: .topLeading) {
            ForEach(Array(ordered.enumerated()), id: \.element.pin.note.id) { index, entry in
              // The **frame** first: it shows what is annotated. A pin on its
              // own leaves you guessing what it refers to, and a misplaced pin
              // does not show at all — which happened, and is what motivated
              // this rendering.
              RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                .strokeBorder(
                  Color.accent.opacity(Tokens.Opacity.annotation),
                  style: StrokeStyle(lineWidth: Tokens.Stroke.regular, dash: [4, 3])
                )
                .frame(width: entry.rect.width, height: entry.rect.height)
                .position(x: entry.rect.midX, y: entry.rect.midY)
                .allowsHitTesting(false)

              badge(number: numbering.number(of: entry.pin.note.id) ?? index + 1, note: entry.pin.note)
                .position(
                  x: min(entry.rect.maxX - Tokens.Space.s2, proxy.size.width - Tokens.Space.s5),
                  y: entry.rect.minY + Tokens.Space.s2
                )
            }
          }
          // Assigned outside the layout pass: writing state from inside a
          // `GeometryReader`'s body is a change published during view update.
          .onAppear { numbering.assign(ordered.map(\.pin.note.id)) }
          .onChange(of: ordered.map(\.pin.note.id)) { _, ids in numbering.assign(ids) }
        }
        .allowsHitTesting(settings.showsDecisions)
        .opacity(settings.showsDecisions ? 1 : 0)
        .animation(reducedMotion ? nil : Motion.toggle, value: settings.showsDecisions)
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
        .frame(width: Tokens.Layout.decisionBadge, height: Tokens.Layout.decisionBadge)
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
  /// Draws the annotation layer for this screen.
  ///
  /// To be applied **once per screen**, at the topmost level: that is where the
  /// geometry of all the content is known. It draws; it presents nothing — see
  /// `decisionSheet(isEnabled:)`.
  func decisionOverlay() -> some View {
    modifier(DecisionOverlay())
  }
}
