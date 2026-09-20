import Observation

/// Records the reader tapping the tab they are already on.
///
/// ## Why the gesture needs a type at all
///
/// It is a native iOS expectation — every Apple app answers it — and nothing in
/// `TabView` reports it: the selection binding is only written when the value
/// *changes*, so tapping the active tab writes nothing at all. The only place
/// that can notice is the binding's setter, in the scene; the only place that
/// can act is the section's own stack, deep inside the tab. This carries the
/// fact between the two.
///
/// ## Why a count and not a boolean
///
/// Because the gesture is repeatable and the reaction must fire every time. A
/// `Bool` set to `true` twice in a row is one change, and the second tap would
/// do nothing — which is precisely the tap that is supposed to scroll a
/// already-rooted section back to the top.
///
/// It is tested with no renderer at all: recording twice is an assertion on an
/// integer.
@Observable
@MainActor
public final class SectionReselection {
  /// How many times each section has been tapped while already selected.
  public private(set) var counts: [AppSection: Int] = [:]

  public init() {}

  public func record(_ section: AppSection) {
    counts[section, default: 0] += 1
  }

  /// The count a section observes. Zero until the reader does it once.
  public func count(_ section: AppSection) -> Int {
    counts[section] ?? 0
  }
}
