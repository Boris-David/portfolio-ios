import Presentation
import Testing
@testable import Composition

/// Launch flags drive the **automated screenshots**, so a flag that silently
/// stops working costs a whole set of captures — and nothing would say so: the
/// app would simply open on its usual tab and the images would look plausible.
struct LaunchArgumentsTests {
  @Test("no flags means the profile tab, annotations off")
  func defaults() {
    let launch = LaunchArguments([])
    #expect(launch.initialSection == .profile)
    #expect(!launch.showsDecisions)
  }

  @Test("-tab selects the named section", arguments: AppSection.allCases)
  func tabFlag(_ section: AppSection) {
    #expect(LaunchArguments(["-tab", section.rawValue]).initialSection == section)
  }

  @Test("an unknown section name falls back rather than failing to launch")
  func unknownSection() {
    #expect(LaunchArguments(["-tab", "nowhere"]).initialSection == .profile)
  }

  /// The bug this exists to prevent: `-tab` as the very last argument used to
  /// read one past the end. A crash before the first frame, in the one code path
  /// only CI takes.
  @Test("-tab with nothing after it does not read past the end")
  func tabFlagWithoutValue() {
    #expect(LaunchArguments(["-decisions", "-tab"]).initialSection == .profile)
  }

  @Test("-decision opens in annotations mode")
  func decisionsFlag() {
    #expect(LaunchArguments(["-decisions"]).showsDecisions)
  }

  @Test("-settings opens the settings sheet")
  func settingsFlag() {
    #expect(LaunchArguments(["-settings"]).opensSettings)
    #expect(!LaunchArguments([]).opensSettings)
  }

  @Test("-route pushes a screen that no tab flag can reach", arguments: [
    ("about", Route.about),
    ("architectures", Route.architectures),
  ])
  func routeFlag(_ pair: (String, Route)) {
    #expect(LaunchArguments(["-route", pair.0]).initialRoute == pair.1)
  }

  /// Only routes that take no argument are reachable. A case study needs a slug,
  /// and a flag that silently matched nothing would be worse than none at all.
  @Test("an unknown or argument-taking route is refused", arguments: ["caseStudy", "nowhere", ""])
  func unknownRoute(_ name: String) {
    #expect(LaunchArguments(["-route", name]).initialRoute == nil)
  }

  @Test("-route with nothing after it does not read past the end")
  func routeFlagWithoutValue() {
    #expect(LaunchArguments(["-decisions", "-route"]).initialRoute == nil)
  }

  /// The flags compose: a screenshot of the settings sheet with annotations on
  /// is one launch, not two.
  @Test("the flags compose")
  func flagsCompose() {
    let launch = LaunchArguments(["-decisions", "-settings", "-tab", "journey"])
    #expect(launch.showsDecisions)
    #expect(launch.opensSettings)
    #expect(launch.initialSection == .journey)
  }
}
