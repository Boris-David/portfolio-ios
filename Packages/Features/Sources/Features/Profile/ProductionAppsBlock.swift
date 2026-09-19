import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The apps in production, on the screen that decides — as a shelf.
///
/// ## Why this is the strongest block in the app
///
/// It is not a claim. Every icon here is an application anybody can download
/// today, and his ticketing layer is inside each one. The argument is made by
/// the objects, not by the sentence above them.
///
/// It was **1 050 pt down the second tab**. A recruiter reading for thirty
/// seconds never reached it.
///
/// ## Why a shelf and not the grid
///
/// The grid is a place you browse; the work tab keeps it. A shelf says "there
/// are many of these, and here is what they look like" in one screen's height,
/// and it is the vocabulary the App Store uses for exactly that. Scrolling it
/// sideways is a discovery, not a requirement — the count is in the heading,
/// so a reader who never touches it has already had the fact.
struct ProductionAppsBlock: View {
  let section: Portfolio.Section?
  let catalogue: AppCatalogue

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      if let section {
        SectionHeader(eyebrow: section.eyebrow, title: section.title)
      }
      shelf
    }
    .reveal()
    .decision(ProfileDecisions.shelf)
  }

  private var shelf: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: Tokens.Space.s3) {
        ForEach(catalogue.ticketing) { app in
          AppCell(app: app)
            .frame(width: Tokens.Layout.shelfCellWidth)
        }
      }
      // The shelf runs the full width of the screen, past the page's gutter,
      // because a row of cards clipped at the margin reads as ending there.
      // The inset puts the first card back on the margin and lets the last one
      // scroll clear of it.
      .scrollTargetLayout()
      .padding(.horizontal, Tokens.Space.s5)
    }
    .padding(.horizontal, -Tokens.Space.s5)
    // Each card comes to rest under the finger instead of stopping wherever
    // the flick ran out. Half a card showing at rest is how a shelf tells the
    // reader there is more — but half a card *at every rest* is a layout that
    // never settles.
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }
}
