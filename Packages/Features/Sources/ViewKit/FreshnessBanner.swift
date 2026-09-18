import DesignSystem
import Domain
import Presentation
import SwiftUI

/// The banner that admits what is being shown.
///
/// It appears **only** when there is something to say. A permanent "up to date"
/// notice is a notice people stop reading, and the day it says something else,
/// nobody sees it.
package struct FreshnessBanner: View {
  private let snapshot: PortfolioSnapshot
  private let language: Language

  public init(snapshot: PortfolioSnapshot, language: Language) {
    self.snapshot = snapshot
    self.language = language
  }

  public var body: some View {
    if let message = FreshnessStyle(language: language).describe(snapshot.origin) {
      HStack(spacing: Tokens.Space.s2) {
        Image(systemName: snapshot.refreshFailure == nil ? "clock" : "wifi.exclamationmark")
          .font(.footnote)
        Text(message)
          .font(Typography.caption)
        Spacer(minLength: 0)
      }
      .foregroundStyle(Color.ink3)
      .padding(.horizontal, Tokens.Space.s4)
      .padding(.vertical, Tokens.Space.s2)
      .frame(maxWidth: .infinity)
      .background(Color.paper2)
      .accessibilityElement(children: .combine)
    }
  }
}
