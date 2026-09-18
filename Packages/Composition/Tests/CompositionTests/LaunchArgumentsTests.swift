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
    #expect(!launch.isBackstageEnabled)
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
    #expect(LaunchArguments(["-backstage", "-tab"]).initialSection == .profile)
  }

  @Test("-backstage opens in annotations mode")
  func backstageFlag() {
    #expect(LaunchArguments(["-backstage"]).isBackstageEnabled)
  }

  @Test("-settings opens the settings sheet")
  func settingsFlag() {
    #expect(LaunchArguments(["-settings"]).opensSettings)
    #expect(!LaunchArguments([]).opensSettings)
  }

  /// The flags compose: a screenshot of the settings sheet with annotations on
  /// is one launch, not two.
  @Test("the flags compose")
  func flagsCompose() {
    let launch = LaunchArguments(["-backstage", "-settings", "-tab", "journey"])
    #expect(launch.isBackstageEnabled)
    #expect(launch.opensSettings)
    #expect(launch.initialSection == .journey)
  }
}
