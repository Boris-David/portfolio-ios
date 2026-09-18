import SwiftUI

/// A note and the exact place it annotates.
struct BackstagePin: Equatable {
  let note: BackstageNote
  let anchor: Anchor<CGRect>

  static func == (lhs: BackstagePin, rhs: BackstagePin) -> Bool {
    lhs.note == rhs.note
  }
}

/// How a screen's annotations are collected.
///
/// A **preference** rather than a registry on the controller: a preference
/// travels up with the view tree, so it empties itself when a view goes away. A
/// registry would have required unregistering on disappearance — and a forgotten
/// `onDisappear` leaves ghost pins on a screen you have already left.
struct BackstagePinsKey: PreferenceKey {
  static var defaultValue: [BackstagePin] { [] }

  static func reduce(value: inout [BackstagePin], nextValue: () -> [BackstagePin]) {
    value.append(contentsOf: nextValue())
  }
}

package extension View {
  /// Annotates this component: in backstage mode it gets a numbered pin that
  /// opens its explanation.
  ///
  /// Outside backstage mode the modifier **changes nothing** — not the layout,
  /// not accessibility, not the touch surface. A demonstration feature that
  /// degraded the ordinary app would be worth nothing.
  ///
  /// - Important: `transformAnchorPreference` and **not** `anchorPreference`.
  ///
  ///   `anchorPreference` **replaces** the subtree's preference value with the
  ///   one it produces. An annotation placed on a container therefore erases
  ///   every annotation inside it — and you only notice by looking at the
  ///   screen: the home `ScrollView`'s annotation made the animated logo's and
  ///   the buttons' disappear, with no error and no warning.
  ///
  ///   `transformAnchorPreference` **adds** to what the descendants already
  ///   produced, which is the semantics wanted here.
  func backstage(_ note: BackstageNote) -> some View {
    transformAnchorPreference(key: BackstagePinsKey.self, value: .bounds) { pins, anchor in
      pins.append(BackstagePin(note: note, anchor: anchor))
    }
  }
}
