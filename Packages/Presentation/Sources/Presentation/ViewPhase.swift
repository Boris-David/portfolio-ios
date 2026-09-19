/// The state of a screen, in four cases and not one more.
///
/// ## Why `initial` **and** `loading` are distinct
///
/// This is the distinction that does all the work, and the first one people
/// remove when they are not paying attention.
///
/// - `initial`: the screen has just appeared, **nothing has been asked for
///   yet**. It shows nothing at all;
/// - `loading`: a request is in flight. It shows a skeleton.
///
/// Merging them produces a flicker on every navigation: the screen shows a
/// skeleton during the fraction of a second before the first call, when it has
/// nothing to wait for. On a fast device that reads as a jolt; on a slow one, as
/// a defect.
///
/// ## Why refreshing is **not** a fifth case
///
/// "Currently refreshing" is **orthogonal** to the phase: a refresh starts from
/// `loaded` as readily as from `failed`. Making it a case would produce
/// combinations nobody can name — `refreshingAfterFailure`? — and force every
/// `switch` to handle them.
///
/// So it is a boolean on the store, beside the phase. Pull-to-refresh needs it
/// anyway: it has to know when to release its indicator, and that does not
/// depend on what is on screen.
public enum ViewPhase<Value: Sendable>: Sendable {
  /// The screen has just appeared. Nothing requested, nothing displayed.
  case initial
  /// A request is in flight, and there is nothing to show in the meantime.
  case loading
  /// There is something to show.
  case loaded(Value)
  /// There is nothing to show, and we know why.
  case failed(PhaseFailure)
}

public extension ViewPhase {
  var value: Value? {
    if case .loaded(let value) = self { value } else { nil }
  }

  var isLoaded: Bool { value != nil }

  /// True as long as the screen has nothing to show — the skeleton decision.
  var isPending: Bool {
    switch self {
    case .initial, .loading: true
    case .loaded, .failed: false
    }
  }
}

extension ViewPhase: Equatable where Value: Equatable {}
