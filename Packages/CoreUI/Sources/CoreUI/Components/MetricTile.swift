import DesignSystem
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
          // ⚠️ A figure never wraps. Three tiles side by side give each about a
          // third of the screen, and `> 99,8` broke across **three lines** —
          // ">", then "99,", then "8". A number cut in half is not a smaller
          // number, it is a defect, and it was on the screen that carries the
          // app's only hard reliability figure.
          //
          // Shrinking is the right answer rather than a smaller size for all
          // three: `~5` keeps its weight, and the one value with five glyphs
          // gives up the points it needs. The floor is set where the caption
          // under it is still smaller.
          .lineLimit(1)
          .minimumScaleFactor(Tokens.TypeScale.body / Tokens.TypeScale.large)
        if let unit {
          Text(unit)
            .font(Typography.heading)
            .foregroundStyle(Color.accent)
            .lineLimit(1)
        }
      }
      // The caption says what the number **means**, and it was set 13 pt in
      // `ink3` — the treatment for a footnote — under a 34 pt figure. A reader
      // who skims takes the number and never learns what it counts.
      Text(caption)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
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
