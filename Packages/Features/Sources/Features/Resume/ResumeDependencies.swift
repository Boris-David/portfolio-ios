import Domain

/// Exactly what the résumé screen needs.
///
/// One port. That is the point of declaring it: a screen that reads a PDF has no
/// business compiling against the preferences store or the event bus, and
/// handing it `AppEnvironment` would let it.
///
/// See `SettingsDependencies` for the full reasoning — including why this is not
/// a dependency container.
public protocol ResumeDependencies: Sendable {
  var resume: any ResumeReading { get }
}
