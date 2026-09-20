import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// One of his own applications, in full: what it is, where to get it, how it
/// was built.
///
/// ## Why a screen of its own and not the case study
///
/// A case study exists for one of these products and not for the other. Routing
/// the list through `Route.caseStudy` would have worked for KCalories and left
/// the portfolio app as a row that opens nothing — so the route is the
/// **product**, and the story is a part of it that may be absent.
///
/// It is reached by presentation, not by a push: a product detail is something
/// you look at and come back from, and the list you came from should still be
/// where you left it.
public struct ProductDetailScreen: View {
  private let product: ProductionApp
  private let study: CaseStudy?
  private let metric: Metric?

  public init(product: ProductionApp, study: CaseStudy?, metric: Metric?) {
    self.product = product
    self.study = study
    self.metric = metric
  }

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s6) {
        ProductHeaderBlock(product: product, study: study, metric: metric)
        if let study, !study.media.isEmpty {
          ProductGalleryBlock(media: study.media)
        }
        if let study {
          ProductStoryBlock(study: study)
        }
      }
      .padding(.top, Tokens.Space.s5)
    }
    .navigationTitle(product.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}
