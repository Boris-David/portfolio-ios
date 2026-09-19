/// Which number each annotation carries, and for how long.
///
/// ## The bug this type exists to kill
///
/// The number used to be the pin's **position in the list of pins currently on
/// screen**, computed fresh on every layout pass. That is stable only while
/// that list is — and it is not: a `List`, a `LazyVGrid` and a horizontal shelf
/// all build and discard their contents as you scroll, so annotated components
/// enter and leave the collected set. Scrolling renumbered everything, and
/// badge 1 stopped being the component that badge 1 had just opened.
///
/// A number handed out on **first sight** cannot do that: whatever is under the
/// reader's finger keeps the number it had when they looked at it.
///
/// ## Why it is a value and not three lines inside the overlay
///
/// Because this is the whole of the defect, and a defect that shipped deserves
/// a test that would have caught it. Inside a `ViewModifier` it would only be
/// checkable by scrolling a simulator and looking; here it is an assertion on a
/// dictionary.
package struct DecisionNumbering: Equatable {
  private var numbers: [String: Int] = [:]

  package init() {}

  /// The number given to a note, if it has been seen.
  package func number(of id: String) -> Int? { numbers[id] }

  /// Hands a number to every note that does not have one, in the order given —
  /// which the overlay supplies as reading order, top to bottom.
  ///
  /// ## The one reset, and why it cannot renumber anything visible
  ///
  /// When **nothing** that was numbered is in the set any more, the reader is
  /// not on that screen any more either: they pushed, popped, or changed tab.
  /// Numbering starts again at one, which is what a new screen should do.
  ///
  /// The test for it is that the two sets are **disjoint**, so at the moment it
  /// fires, every note on screen is one that had no number. Nothing the reader
  /// can see changes.
  package mutating func assign(_ ids: [String]) {
    guard !ids.isEmpty else { return }
    if Set(numbers.keys).isDisjoint(with: ids) { numbers = [:] }

    var next = (numbers.values.max() ?? 0) + 1
    for id in ids where numbers[id] == nil {
      numbers[id] = next
      next += 1
    }
  }
}
