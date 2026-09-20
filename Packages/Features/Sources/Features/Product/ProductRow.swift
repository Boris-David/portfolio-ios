import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// One of his own applications, as a row: the icon, the name, what it is.
///
/// The sentence is the study's subtitle when there is a study, and the app's
/// own `summary` otherwise — the product with no longer story still has to say
/// what it is, and a row showing only a name above a chevron says nothing.
struct ProductRow: View {
  let product: ProductionApp
  let study: CaseStudy?

  @Environment(\.present) private var present

  var body: some View {
    Button {
      present(.reading(.product(slug: product.slug)))
    } label: {
      HStack(spacing: Tokens.Space.s3) {
        ContentImage(product.slug, kind: .appIcon)
          .frame(width: Tokens.Layout.appIconSide, height: Tokens.Layout.appIconSide)
          .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
              .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
          )
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
          Text(product.name)
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
          if let sentence {
            Text(sentence)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Image(systemName: "chevron.right")
          .font(.system(size: Tokens.Icon.caption, weight: .semibold))
          .foregroundStyle(Color.ink3)
          .accessibilityHidden(true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel([product.name, sentence].compactMap { $0 }.joined(separator: ", "))
    .accessibilityAddTraits(.isButton)
  }

  private var sentence: String? {
    study?.subtitle ?? product.summary
  }
}

/// A project that is readable rather than published: a component, an exercise.
///
/// It has no store page and no case study, so the row carries its link itself
/// instead of opening a detail that would hold one sentence and a button.
struct OpenProjectRow: View {
  let project: OpenProject

  @Environment(\.openURL) private var openURL
  @Localized(.interface) private var text

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(project.name)
        .font(Typography.bodyStrong)
        .foregroundStyle(Color.ink)
      RichTextView(project.description, font: Typography.secondary, color: .ink2)
      if let source = project.sourceURL.flatMap(URL.init(string:)) {
        Button { openURL(source) } label: {
          Label(text(InterfaceText.sourceCode), systemImage: "arrow.up.right")
            .font(Typography.secondary)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accent)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
