import DesignSystem
import SwiftUI

/// A technical chip — `actor`, `SwiftUI`, `fastlane`.
///
/// Deliberately quiet: a list of technologies is not an argument, it is context.
/// Bringing it forward would suggest a candidate is judged by keyword count.
public struct Chip: View {
  private let label: String
  private let systemImage: String?
  private let emphasis: Emphasis

  public enum Emphasis {
    case neutral
    /// For the handful of chips that genuinely matter.
    case accented
  }

  /// - Parameter systemImage: an SF Symbol, when the chip names something a
  ///   glyph makes faster to read — a sport, a hobby. It stays **optional**:
  ///   a technology has no glyph that is not a logo, and a made-up one would be
  ///   worse than none. An absent symbol simply leaves the label alone.
  public init(_ label: String, systemImage: String? = nil, emphasis: Emphasis = .neutral) {
    self.label = label
    self.systemImage = systemImage
    self.emphasis = emphasis
  }

  public var body: some View {
    content
      .font(Typography.caption)
      .foregroundStyle(emphasis == .accented ? Color.accent : Color.ink2)
      .padding(.horizontal, Tokens.Space.s3)
      .padding(.vertical, Tokens.Space.s1 + 2)
      .background(
        Capsule().fill(emphasis == .accented ? Color.accentWash : Color.paper2)
      )
      .overlay(Capsule().strokeBorder(Color.line, lineWidth: emphasis == .accented ? 0 : 1))
  }

  @ViewBuilder
  private var content: some View {
    if let systemImage {
      // `Label` and not an `HStack`: it keeps the glyph on the text's baseline
      // as the type scale grows, and VoiceOver reads the label once instead of
      // announcing an image beside it.
      Label(label, systemImage: systemImage)
        .labelStyle(.titleAndIcon)
        .imageScale(.small)
    } else {
      Text(label)
    }
  }
}
