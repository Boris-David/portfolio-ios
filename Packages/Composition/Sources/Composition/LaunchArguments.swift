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

  init(_ arguments: [String]) {
    isBackstageEnabled = arguments.contains("-backstage")
    opensSettings = arguments.contains("-settings")
    initialSection = Self.section(in: arguments) ?? .profile
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
