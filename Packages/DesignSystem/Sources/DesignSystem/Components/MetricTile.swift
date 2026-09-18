import SwiftUI

/// A figure brought forward, and what it means.
///
/// The number **counts up** as it reaches the screen — when the source asks for
/// it. That is not an inference from its shape: "~5" could be animated, and we
/// choose not to, because animating an approximation lends it a precision it
/// does not have.
public struct MetricTile: View {
  private let value: String
  private let unit: String?
  private let caption: String
  private let countTo: Int?

  @State private var displayed: Double = 0
  @State private var hasAppeared = false
  @ReducedMotion private var reducedMotion

  public init(value: String, unit: String?, caption: String, countTo: Int? = nil) {
    self.value = value
    self.unit = unit
    self.caption = caption
    self.countTo = countTo
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s1) {
        Text(renderedValue)
          .font(Typography.metric)
          .foregroundStyle(Color.ink)
          // Changing digits must occupy a stable width, or the tile shivers
          // for the whole count.
          .monospacedDigit()
          .contentTransition(.numericText())
        if let unit {
          Text(unit)
            .font(Typography.heading)
            .foregroundStyle(Color.accent)
        }
      }
      Text(caption)
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // A figure and its caption are **one** piece of information. Separated,
    // VoiceOver announces "6" and then, later, "of iOS engineering" — two
    // fragments, neither of which means anything.
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(value) \(unit ?? "") \(caption)")
    .onAppear(perform: startCounting)
  }

  private var renderedValue: String {
    guard let countTo, hasAppeared, !reducedMotion else { return value }
    return displayed >= Double(countTo) ? value : String(Int(displayed))
  }

  private func startCounting() {
    guard let countTo, !hasAppeared, !reducedMotion else { return }
    hasAppeared = true
    withAnimation(Motion.animation(Tokens.Ease.out, duration: Tokens.Duration.counter)) {
      displayed = Double(countTo)
    }
  }
}
