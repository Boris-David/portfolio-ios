import DesignSystem
import SwiftUI

/// A figure brought forward — the number and its unit, and nothing else.
///
/// The number **counts up** as it reaches the screen, when the source asks for
/// it. That is not an inference from its shape: "~5" could be animated, and we
/// choose not to, because animating an approximation lends it a precision it
/// does not have.
///
/// ## Why it stops at the figure
///
/// It carried its caption too, as a tile. Then the captions became sentences —
/// *"that is how many people use an app I have contributed to, today"* — and a
/// sentence needs a measure that a third of a phone screen does not have. The
/// figure and the words are laid out by whoever knows how much room there is;
/// this type draws the figure.
public struct MetricValueView: View {
  private let value: String
  private let unit: String?
  private let countTo: Int?

  @State private var displayed: Double = 0
  @State private var hasAppeared = false
  @ReducedMotion private var reducedMotion

  public init(value: String, unit: String?, countTo: Int? = nil) {
    self.value = value
    self.unit = unit
    self.countTo = countTo
  }

  public var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s1) {
      Text(renderedValue)
        .font(Typography.metric)
        .foregroundStyle(Color.ink)
        // Changing digits must occupy a stable width, or the figure shivers
        // for the whole count.
        .monospacedDigit()
        .contentTransition(.numericText())
        // ⚠️ A figure never wraps. In a row of three tiles each had about a
        // third of the screen, and `> 99,8` broke across **three lines** —
        // ">", then "99,", then "8". A number cut in half is not a smaller
        // number, it is a defect, and it was on the screen that carries the
        // app's only hard reliability figure.
        .lineLimit(1)
        .minimumScaleFactor(Tokens.TypeScale.body / Tokens.TypeScale.large)
      if let unit {
        Text(unit)
          .font(Typography.heading)
          .foregroundStyle(Color.accent)
          .lineLimit(1)
      }
    }
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
