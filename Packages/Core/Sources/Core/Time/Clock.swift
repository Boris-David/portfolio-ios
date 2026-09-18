import Foundation

/// What time it is — as a **dependency**, not as a global function.
///
/// ## Why this exists
///
/// Three layers already injected a clock, and each one invented its own shape:
/// `clock: @escaping @Sendable () -> Date`. Three closures, three conventions,
/// and nothing that says they mean the same thing. A test that wants to move
/// time forward has to know which of the three it is holding.
///
/// One protocol ends that. And it is the smallest possible illustration of why
/// `Core` exists: not to collect leftovers, but to stop the same abstraction
/// being written three times slightly differently.
///
/// ## Why not Swift's `Clock`
///
/// `Swift.Clock` measures **durations** — it answers "how long since", for
/// sleeping and for deadlines. It deliberately does not answer "what is today's
/// date", because a monotonic clock must not jump when the user changes the
/// time zone. Here the question really is "what date is it", so this is a
/// different thing wearing a similar name.
public protocol DateProviding: Sendable {
  var now: Date { get }
}
