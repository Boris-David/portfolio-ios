import Core
import Domain

/// Joins the generic bus in `Core` to the application's vocabulary in `Domain`.
///
/// This conformance is three lines and it is the whole point of the adapter
/// layer: `Core` provides a machine that carries anything, `Domain` says what
/// this application considers a fact, and neither has to know the other exists.
///
/// It lives in `Data` and not in `Composition` because it is a translation, not
/// a wiring decision — and because a second application built on this `Core`
/// would write its own, right here, without touching either side.
extension EventBus: @retroactive EventPublishing where Event == AppEvent {}

/// The bus this application uses.
///
/// A name rather than `EventBus<AppEvent>` written out at every call site: the
/// generic parameter is an implementation detail of the mechanism, not something
/// a reader of the composition root needs to parse.
public typealias AppEventBus = EventBus<AppEvent>
