import Decisions
import DesignSystem
import Domain
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// The banner that admits what is being shown — and, on a tap, says exactly why.
///
/// It appears **only** when there is something to say. A permanent "up to date"
/// notice is a notice people stop reading, and the day it says something else,
/// nobody sees it.
///
/// ## Why a popover and not a sheet
///
/// The question it answers — *where did this come from?* — is a footnote about
/// the thing the reader is looking at. A popover **points at** the banner it
/// belongs to; a sheet covers the screen and severs the connection between the
/// question and what prompted it.
///
/// `presentationCompactAdaptation(.popover)` keeps that on iPhone. Without it,
/// SwiftUI turns every popover into a sheet in a compact size class — which is
/// a reasonable default for a menu and the wrong one for a footnote.
///
/// ## Why it sits in `FeatureKit` and not in `ViewKit`
///
/// Because it carries a decision annotation, and `Decisions` depends on
/// `ViewKit`. Declaring a `DesignDecision` down there is a module dependency
/// cycle — which the compiler refused, immediately and by name. The straight
/// line `ViewKit → Decisions → FeatureKit` is exactly what makes that mistake
/// impossible to ship rather than merely discouraged.
package struct FreshnessBanner: View {
  private let snapshot: PortfolioSnapshot
  private let language: Language

  @State private var isShowingProvenance = false
  @Localized(.interface) private var text

  public init(snapshot: PortfolioSnapshot, language: Language) {
    self.snapshot = snapshot
    self.language = language
  }

  public var body: some View {
    if let message = FreshnessStyle(language: language).describe(snapshot.origin) {
      Button {
        isShowingProvenance = true
      } label: {
        HStack(spacing: Tokens.Space.s2) {
          Image(systemName: snapshot.refreshFailure == nil ? "clock" : "wifi.exclamationmark")
            .font(.footnote)
          Text(message)
            .font(Typography.caption)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          Image(systemName: "info.circle")
            .font(.footnote)
        }
        .foregroundStyle(Color.ink3)
        .padding(.horizontal, Tokens.Space.s4)
        .padding(.vertical, Tokens.Space.s2)
        .frame(maxWidth: .infinity)
        .background(Color.paper2)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(message)
      .accessibilityHint(text(InterfaceText.provenanceHint))
      .popover(isPresented: $isShowingProvenance) {
        provenance
          .presentationCompactAdaptation(.popover)
      }
      .decision(KitDecisions.popover)
    }
  }

  private var provenance: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(text(InterfaceText.provenanceTitle)).eyebrowStyle()
      Text(FreshnessStyle(language: language).describe(snapshot.origin) ?? "")
        .font(Typography.secondary)
        .foregroundStyle(Color.ink)
      // The fingerprint, shown rather than hidden: two snapshots with the same
      // version carry the same content whatever their origin, and somebody
      // inspecting this app has every reason to check that for themselves.
      HStack(spacing: Tokens.Space.s2) {
        Text(text(InterfaceText.provenanceVersion))
          .font(Typography.caption)
          .foregroundStyle(Color.ink3)
        Text(snapshot.contentVersion)
          .font(Typography.code)
          .foregroundStyle(Color.accent)
          .textSelection(.enabled)
      }
    }
    .padding(Tokens.Space.s5)
    .frame(maxWidth: Tokens.Layout.popoverWidth)
  }
}
