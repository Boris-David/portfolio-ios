import DesignSystem
import SwiftUI

/// A technical chip — `actor`, `SwiftUI`, `fastlane`.
///
/// Deliberately quiet: a list of technologies is not an argument, it is context.
/// Bringing it forward would suggest a candidate is judged by keyword count.
public struct Chip: View {
  private let label: String
  private let emphasis: Emphasis

  public enum Emphasis {
    case neutral
    /// For the handful of chips that genuinely matter.
    case accented
  }

  public init(_ label: String, emphasis: Emphasis = .neutral) {
    self.label = label
    self.emphasis = emphasis
  }

  public var body: some View {
    Text(label)
      .font(Typography.caption)
      .foregroundStyle(emphasis == .accented ? Color.accent : Color.ink2)
      .padding(.horizontal, Tokens.Space.s3)
      .padding(.vertical, Tokens.Space.s1 + 2)
      .background(
        Capsule().fill(emphasis == .accented ? Color.accentWash : Color.paper2)
      )
      .overlay(Capsule().strokeBorder(Color.line, lineWidth: emphasis == .accented ? 0 : 1))
  }
}
