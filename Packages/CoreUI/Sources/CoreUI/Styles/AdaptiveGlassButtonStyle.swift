import DesignSystem
import SwiftUI

/// The app's buttons: glass on iOS 26, bordered on iOS 18, in three roles.
///
/// ## Why one style with a role rather than three styles
///
/// Because the three differ only in what they say, never in how they behave.
/// Press, disabled and loading are identical in all of them — and the day one of
/// them drifts is the day a reader learns that a press means something different
/// here than it did on the previous screen.
public struct AdaptiveGlassButtonStyle: ButtonStyle {
  /// What the button claims, which is the only thing the three variants disagree
  /// on.
  public enum Role: Sendable {
    /// The one action a screen is built around. One per screen.
    case primary
    /// Everything else that is still an action.
    case secondary
    /// Something that cannot be undone.
    case destructive
  }

  private let role: Role
  private let isLoading: Bool

  public init(role: Role = .secondary, isLoading: Bool = false) {
    self.role = role
    self.isLoading = isLoading
  }

  @Environment(\.isEnabled) private var isEnabled

  public func makeBody(configuration: Configuration) -> some View {
    label(configuration)
      // Touch feedback is the same in all three roles and in both worlds: it is
      // information, not decoration, and it does not depend on the material.
      .scaleEffect(configuration.isPressed ? Tokens.Layout.pressedScale : 1)
      .opacity(isEnabled ? 1 : Tokens.Opacity.disabled)
      .animation(Motion.interactive, value: configuration.isPressed)
      // A button that is working is not a button you may press again. Saying so
      // with `allowsHitTesting` rather than `.disabled` keeps the label at full
      // strength: this is busy, not unavailable, and the two must not look alike.
      .allowsHitTesting(!isLoading)
  }

  /// The colour the label takes.
  ///
  /// `.destructive` uses the **system** red rather than a brand token. It is a
  /// semantic of the platform — the same red the reader has been taught by every
  /// other app on the phone — and a portfolio's palette has no business
  /// redefining what "this cannot be undone" looks like.
  private var foreground: Color {
    switch role {
    case .primary: Color.onAccent
    case .secondary: Color.ink
    case .destructive: Color.red
    }
  }

  private var fill: Color? {
    switch role {
    case .primary: Color.accent
    case .secondary, .destructive: nil
    }
  }

  /// ⚠️ **`glassEffect` applies to the view, never to a background behind it.**
  ///
  /// A previous version put the glass inside a `.background { … }`. It compiles,
  /// it raises no warning — and the label **disappears**. iOS 26 glass is not a
  /// layer you stack behind: it is a treatment of the view it is applied to, and
  /// it composes its own content. Put in the background, it covers the text.
  ///
  /// Found on iPad, then recognised on iPhone — where I had taken it for a
  /// button simply hidden behind the tab bar. A misread screenshot is worth an
  /// unseen regression.
  ///
  /// And a **prominent** button does not render the same in both worlds.
  /// `Glass.tint(_:)` guarantees legibility on iOS 26; the same tint at low
  /// opacity over a translucent material gives, in light theme on iOS 18, white
  /// on pale. The fallback is a solid accent fill — what iOS 18 itself uses for
  /// a primary action.
  @ViewBuilder
  private func label(_ configuration: Configuration) -> some View {
    let content = ZStack {
      // Both states occupy the frame at once, so the button does not resize when
      // it starts working — a control that jumps under the finger that pressed
      // it reads as a glitch, not as progress.
      configuration.label.opacity(isLoading ? 0 : 1)
      if isLoading {
        ProgressView().controlSize(.small).tint(foreground)
      }
    }
    .font(Typography.bodyStrong)
    .foregroundStyle(foreground)
    .padding(.horizontal, Tokens.Space.s4)
    .frame(minHeight: Tokens.Accessibility.minimumTouchTarget)

    if #available(iOS 26.0, *) {
      content.glassEffect(Glass.regular.tint(fill).interactive(), in: Capsule())
    } else if let fill {
      content.background(Capsule().fill(fill))
    } else {
      content
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular))
    }
  }
}

public extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
  /// A screen's primary action — one per screen.
  static var adaptiveGlassProminent: AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(role: .primary)
  }

  /// A secondary floating button.
  static var adaptiveGlass: AdaptiveGlassButtonStyle { AdaptiveGlassButtonStyle() }

  /// An action that cannot be undone.
  static var adaptiveGlassDestructive: AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(role: .destructive)
  }

  /// A primary action that is currently working.
  static func adaptiveGlassProminent(isLoading: Bool) -> AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(role: .primary, isLoading: isLoading)
  }
}
