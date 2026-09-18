import CoreUI
import DesignSystem
import Domain
import Presentation
import SwiftUI
import ViewKit

/// One codebase: what it is, the pattern it follows, and what the files show.
///
/// The pattern is named by the card and argued by the table above — the card
/// never restates the trade-offs. That is the same rule the source applies to
/// itself: written once, pointed at from everywhere, so that no copy can drift.
struct CodebaseCard: View {
  let project: ProjectArchitecture

  @Chrome private var chrome

  var body: some View {
    Surface {
      VStack(alignment: .leading, spacing: Tokens.Space.s3) {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s2) {
          Text(project.name)
            .font(Typography.heading)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: Tokens.Space.s2)
          Chip(project.pattern.name, emphasis: .accented)
        }

        Text(project.context)
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)

        WrappingRow {
          ForEach(project.stack, id: \.self) { Chip($0) }
        }

        if !project.evidence.isEmpty {
          measurements
        }

        RichTextView(project.reading, font: Typography.secondary)
      }
    }
  }

  /// The counts, when there are any.
  ///
  /// A codebase with nothing worth counting simply does not show the block. The
  /// alternative — an empty heading, or a dash — would claim a measurement was
  /// taken and came back empty, which is not what happened.
  private var measurements: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(chrome.whatTheFilesShow).eyebrowStyle()
      ForEach(project.evidence) { EvidenceRow(evidence: $0) }
    }
    .padding(.top, Tokens.Space.s1)
  }
}
