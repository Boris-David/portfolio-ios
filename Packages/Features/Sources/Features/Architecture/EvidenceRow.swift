import DesignSystem
import Domain
import SwiftUI

/// One measurement: a suffix, and how many types carry it.
struct EvidenceRow: View {
  let evidence: ArchitectureEvidence

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s3) {
      Text(evidence.symbol)
        .font(Typography.code)
        .foregroundStyle(Color.ink2)
      // The counts right-align against the card's edge rather than sitting in a
      // hand-measured column: a `Spacer` does it for free, and stays correct at
      // every Dynamic Type size.
      Spacer(minLength: Tokens.Space.s2)
      Text(evidence.count.formatted())
        .font(Typography.bodyStrong)
        // Digits of equal width: without it, the column of figures shivers as
        // soon as two of them differ in shape.
        .monospacedDigit()
        .foregroundStyle(Color.accent)
    }
    // A figure and what it counts are **one** announcement, or VoiceOver reads
    // "ViewModel", then something else, then "325".
    .accessibilityElement(children: .combine)
  }
}
