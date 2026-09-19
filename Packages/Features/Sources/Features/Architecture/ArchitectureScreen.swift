import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The architecture patterns, compared — and the codebases read against them.
///
/// ## Why it is a push and not a tab
///
/// It is a **reading**: you go into it, and you come back. A tab is somewhere
/// you live, and a fifth one would have pushed the bar past the range where its
/// labels stay legible. It hangs off the decision tab because that tab already
/// answers "how is this built", and this screen answers the same question about
/// the codebases behind the career.
///
/// ## What it deliberately does not say
///
/// No repository, no module, no client, no provider. A pattern is a public
/// thing; the code that implements it at an employer is not. The counts are the
/// shape of the code — suffixes and how many types carry them — which is exactly
/// what the reading claims and nothing more.
public struct ArchitectureScreen: View {
  private let study: ArchitectureStudy

  @Localized(.interface) private var text

  public init(study: ArchitectureStudy) {
    self.study = study
  }

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        header
        PatternComparisonBlock(patterns: study.patterns)
        codebases
      }
      .padding(.top, Tokens.Space.s4)
    }
    .background(Color.paper)
    .navigationTitle(text(InterfaceText.architecturePatterns))
    .navigationBarTitleDisplayMode(.inline)
  }

  /// No title in the page: the navigation bar already carries it, and repeating
  /// it costs the first screenful for a word the reader has just read.
  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      RichTextView(study.intro)
      Text(text(InterfaceText.countsTakenOn, study.verifiedOn))
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
    }
  }

  private var codebases: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.codebases)).eyebrowStyle()

      VStack(spacing: Tokens.Space.s3) {
        ForEach(study.projects) { project in
          CodebaseCard(project: project)
        }
      }
    }
    .reveal()
  }
}
