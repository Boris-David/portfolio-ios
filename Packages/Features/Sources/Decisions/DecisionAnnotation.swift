import SwiftUI

/// A note and the exact place it annotates.
struct DecisionPin: Equatable {
  let note: DesignDecision
  let anchor: Anchor<CGRect>

  static func == (lhs: DecisionPin, rhs: DecisionPin) -> Bool {
    lhs.note == rhs.note
  }
}

/// How a screen's annotations are collected.
///
/// A **preference** rather than a registry on the controller: a preference
/// travels up with the view tree, so it empties itself when a view goes away. A
/// registry would have required unregistering on disappearance — and a forgotten
/// `onDisappear` leaves ghost pins on a screen you have already left.
struct DecisionPinsKey: PreferenceKey {
  static var defaultValue: [DecisionPin] { [] }

  static func reduce(value: inout [DecisionPin], nextValue: () -> [DecisionPin]) {
    value.append(contentsOf: nextValue())
  }
}

package extension View {
  /// Annotates this component: in decision mode it gets a numbered pin that
  /// opens its explanation.
  ///
  /// Outside decision mode the modifier **changes nothing** — not the layout,
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
  func decision(_ note: DesignDecision) -> some View {
    transformAnchorPreference(key: DecisionPinsKey.self, value: .bounds) { pins, anchor in
      pins.append(DecisionPin(note: note, anchor: anchor))
    }
  }
}
