import CoreUI
import DesignSystem
import Presentation
import SwiftUI

/// A toast, drawn. It decides nothing — `ToastCenter` already did.
package struct ToastView: View {
  private let toast: Toast
  private let dismiss: () -> Void

  package init(_ toast: Toast, dismiss: @escaping () -> Void) {
    self.toast = toast
    self.dismiss = dismiss
  }

  package var body: some View {
    HStack(spacing: Tokens.Space.s3) {
      Image(toast.icon)
        .font(.system(size: Tokens.Icon.inline, weight: .semibold))
        .foregroundStyle(tint)
      Text(toast.message)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.vertical, Tokens.Space.s3)
    .navigationGlass(in: Capsule())
    // A toast is a **navigation-layer** surface laid over content, which is the
    // one place Liquid Glass belongs. Putting it on the content underneath would
    // be the mistake this design system refuses to make possible.
    .contentShape(Capsule())
    .onTapGesture(perform: dismiss)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(toast.message)
    .accessibilityAddTraits(.isStaticText)
    .accessibilityAction(named: Text(verbatim: "Dismiss"), dismiss)
  }

  private var tint: Color {
    switch toast.kind {
    case .succeeded: .ok
    case .failed: .accent
    case .informed: .ink2
    }
  }
}

public extension View {
  /// Lays the announcement layer over this screen.
  ///
  /// ## Why `.overlay` and not a `ZStack` in every screen
  ///
  /// Written once, at the shell, so a screen never has to remember it — and so
  /// the toast is guaranteed to sit above everything the screen draws, whatever
  /// the screen draws.
  ///
  /// ## ⚠️ Why the transition is on the toast and not on the overlay
  ///
  /// `.transition` needs a view whose **identity** changes. `Toast.id` increases
  /// on every announcement, so two identical messages in a row are two views and
  /// the second one animates in. Keyed on the message, the second would be
  /// considered the same view and nothing would move — the reader would think
  /// their second tap did nothing.
  func toasts(_ center: ToastCenter) -> some View {
    overlay(alignment: .bottom) {
      if let toast = center.current {
        ToastView(toast) { center.dismiss() }
          .id(toast.id)
          .padding(.bottom, Tokens.Space.s6)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(Motion.toggle, value: center.current)
    .feedback(on: center.current) { _, new in
      switch new?.kind {
      case .succeeded: .succeeded
      case .failed: .failed
      case .informed, nil: nil
      }
    }
  }
}
