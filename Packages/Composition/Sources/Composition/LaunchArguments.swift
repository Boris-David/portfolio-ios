import Foundation
import Presentation

/// The launch flags the app understands, read once and typed.
///
/// ## Why flags exist at all in a portfolio app
///
/// They serve **automated screenshots**. A capture of the decision overlay, or
/// of the Journey tab, cannot be taken without somebody touching the screen —
/// and a capture that cannot be reproduced never makes it into CI. Two flags
/// remove the hand:
///
///     xcrun simctl launch <device> dev.amissan.portfolio -decision
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
  let showsDecisions: Bool
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
  /// A different API base, for development and for captures.
  ///
  /// ## Why this is not a risk worth refusing
  ///
  /// Launch arguments cannot be set by somebody who merely has the app: they
  /// need a debugger or `simctl`, which means the device is already under the
  /// control of whoever is passing them. What it buys is real — a resource that
  /// is not deployed yet can be seen, and every screen that reads it can be
  /// captured before the API ships rather than after.
  ///
  /// It is also the honest alternative to the thing people do instead, which is
  /// to edit the production URL, take the screenshot, and forget to change it
  /// back.
  ///
  ///     xcrun simctl launch <device> dev.amissan.portfolio -api http://127.0.0.1:8788
  let apiBaseURL: URL?

  init(_ arguments: [String]) {
    showsDecisions = arguments.contains("-decisions")
    opensSettings = arguments.contains("-settings")
    opensResume = arguments.contains("-resume")
    initialRoute = Self.route(in: arguments)
    apiBaseURL = Self.value(after: "-api", in: arguments).flatMap(URL.init(string:))
    initialSection = Self.section(in: arguments) ?? .profile
  }

  /// The route named after `-route`, if it is one the app knows.
  ///
  /// Only the routes that take **no argument** are reachable this way: a case
  /// study needs a slug, and a flag that silently matched nothing would be worse
  /// than one that does not exist.
  /// The argument that follows a flag, if the flag is present and not last.
  ///
  /// Written once: three flags take a value, and three hand-rolled index walks
  /// would be three chances to read one past the end — which is exactly the
  /// crash `-tab` had, before the first frame, on the one path only CI took.
  private static func value(after flag: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: flag) else { return nil }
    let next = arguments.index(after: index)
    guard next < arguments.endIndex else { return nil }
    return arguments[next]
  }

  private static func route(in arguments: [String]) -> Route? {
    guard let name = Self.value(after: "-route", in: arguments) else { return nil }
    return switch name {
    case "about": .about
    case "architectures": .architectures
    case "allApps": .allApps
    default: nil
    }
  }

  private static func section(in arguments: [String]) -> AppSection? {
    Self.value(after: "-tab", in: arguments).flatMap(AppSection.init(rawValue:))
  }
}
