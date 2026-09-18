import Foundation
import Presentation

/// The launch flags the app understands, read once and typed.
///
/// ## Why flags exist at all in a portfolio app
///
/// They serve **automated screenshots**. A capture of the backstage overlay, or
/// of the Journey tab, cannot be taken without somebody touching the screen —
/// and a capture that cannot be reproduced never makes it into CI. Two flags
/// remove the hand:
///
///     xcrun simctl launch <device> dev.amissan.portfolio -backstage
///     xcrun simctl launch <device> dev.amissan.portfolio -tab journey
///
/// ## Why a type and not two reads of `ProcessInfo`
///
/// Because `ProcessInfo.processInfo` is global state, and a view that reads
/// global state cannot be tested at any other value. This takes the arguments as
/// a parameter; `.current` is the one place that touches the process, and the
/// tests build their own.
struct LaunchArguments: Sendable {
  /// What the running process was launched with.
  static let current = LaunchArguments(ProcessInfo.processInfo.arguments)

  let initialSection: AppSection
  let isBackstageEnabled: Bool
  /// Opens the settings sheet on launch. Same reason as the other two: a sheet
  /// cannot be captured without somebody tapping, and a screenshot nobody can
  /// reproduce never reaches CI.
  ///
  ///     xcrun simctl launch <device> dev.amissan.portfolio -settings
  let opensSettings: Bool
  /// Opens the résumé cover on launch, same reason again.
  let opensResume: Bool
  /// A route to push on launch, so a **pushed** screen can be captured.
  ///
  /// The tab flags reach the four roots and the two covers; nothing reached a
  /// destination inside a stack. The architecture comparison — the one screen a
  /// `Grid` exists for — was invisible to the matrix because of it.
  ///
  ///     xcrun simctl launch <device> dev.amissan.portfolio -route architectures
  let initialRoute: Route?

  init(_ arguments: [String]) {
    isBackstageEnabled = arguments.contains("-backstage")
    opensSettings = arguments.contains("-settings")
    opensResume = arguments.contains("-resume")
    initialRoute = Self.route(in: arguments)
    initialSection = Self.section(in: arguments) ?? .profile
  }

  /// The route named after `-route`, if it is one the app knows.
  ///
  /// Only the routes that take **no argument** are reachable this way: a case
  /// study needs a slug, and a flag that silently matched nothing would be worse
  /// than one that does not exist.
  private static func route(in arguments: [String]) -> Route? {
    guard let flag = arguments.firstIndex(of: "-route") else { return nil }
    let next = arguments.index(after: flag)
    guard next < arguments.endIndex else { return nil }
    return switch arguments[next] {
    case "about": .about
    case "architectures": .architectures
    case "allApps": .allApps
    default: nil
    }
  }

  private static func section(in arguments: [String]) -> AppSection? {
    guard let flag = arguments.firstIndex(of: "-tab") else { return nil }
    let next = arguments.index(after: flag)
    // A bounded read: asking for the value after a flag that ends the list must
    // not bring the app down before it has drawn anything.
    guard next < arguments.endIndex else { return nil }
    return AppSection(rawValue: arguments[next])
  }
}
