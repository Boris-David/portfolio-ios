import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// A published figure and the sentence that says what it means.
///
/// ## Why the sentence sits under the figure, and not beside it
///
/// Three figures side by side was the shape until the captions became
/// sentences. Measured on a 393 pt phone: the gutters leave 353 pt, the widest
/// figure — `> 99,9 %` — takes about 145 pt of it, and what is left for the
/// words is roughly **26 characters a line**. Justified text needs about forty
/// to spread its slack across enough word gaps; at 26 the gaps show, which is
/// the exact defect the accessibility fallback exists to avoid.
///
/// Stacked, the sentence gets the whole column. The figures still align — they
/// all start at the same margin — and so do the sentences. That is what the
/// author asked for; the axis is the part the measure decided.
package struct MetricRow: View {
  private let metric: Metric

  package init(_ metric: Metric) {
    self.metric = metric
  }

  package var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      MetricValueView(value: metric.value, unit: metric.unit, countTo: metric.countTo)
      ProseView(metric.detail, role: .secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // A figure and its sentence are **one** piece of information. Separated,
    // VoiceOver announces "6" and then, later, "years of iOS engineering" —
    // two fragments, neither of which means anything.
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(metric.value) \(metric.unit ?? ""). \(metric.detail)")
  }
}
