import Domain

/// Exactly what the settings screen needs, and nothing else.
///
/// ## Why this exists instead of passing `AppEnvironment` around
///
/// The composition root holds one value with every dependency in it. Handing
/// that value to a feature is the easy thing and it is an Interface Segregation
/// violation: the settings screen would compile against the portfolio reader,
/// the résumé reader, the connectivity monitor — none of which it uses, all of
/// which it would then be free to start using.
///
/// A protocol declared **by the feature** inverts that. The feature states its
/// needs; the composition root proves it can meet them by conforming. Three
/// things follow:
///
/// - a test builds two lines of doubles instead of a whole environment;
/// - adding a dependency to the app cannot silently widen what a screen can
///   reach;
/// - reading this file tells you what this screen touches, which no amount of
///   reading `AppEnvironment` ever will.
///
/// ## Why not a container
///
/// Because a container answers `resolve(PreferencesStoring.self)` at runtime,
/// and a missing registration is then a crash on the screen nobody opened before
/// shipping. Here the same mistake does not compile. The graph also stays
/// **readable**: every dependency is named at the site that takes it, instead of
/// being registered somewhere else entirely.
public protocol SettingsDependencies: Sendable {
  var preferences: any PreferencesStoring { get }
  var events: any EventPublishing { get }
}
