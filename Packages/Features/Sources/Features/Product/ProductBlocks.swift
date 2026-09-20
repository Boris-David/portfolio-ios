import CoreUI
import Decisions
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The product, its store listing, and the one figure that says it holds up.
struct ProductHeaderBlock: View {
  let product: ProductionApp
  let study: CaseStudy?
  let metric: Metric?

  @Environment(\.openURL) private var openURL
  @Environment(\.dynamicTypeSize) private var typeSize
  @Localized(.interface) private var text

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      // ⚠️ The icon keeps its size and the layout stacks, rather than the icon
      // scaling with the text.
      //
      // An app icon is a fixed object — it is the same square the reader has on
      // their home screen — so growing it with the type scale would be growing
      // a picture because a sentence got longer. What has to give is the
      // arrangement: beside a 76 pt icon at AX5, the title had a column three
      // words wide and ran to five lines.
      if typeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: Tokens.Space.s4) { identity }
          .accessibilityElement(children: .combine)
      } else {
        HStack(alignment: .top, spacing: Tokens.Space.s4) { identity }
          .accessibilityElement(children: .combine)
      }

      if let study, let intro = study.intro {
        Text(intro.plain)
          .font(Typography.body)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)
      }

      // Whichever links the product actually has.
      //
      // The store listing leads when there is one: it is what somebody reading
      // a portfolio taps. Where there is none — an app of his own that is
      // readable before it is downloadable — the repository takes the primary
      // place rather than leaving the card with nothing to do.
      VStack(spacing: Tokens.Space.s2) {
        if let store = product.appStoreURL.flatMap(URL.init(string:)) {
          Button { openURL(store) } label: {
            Label(text(InterfaceText.viewOnAppStore), systemImage: "arrow.up.right")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.adaptiveGlassProminent)
          .decision(ProductDecisions.store)
        }
        if let source = product.sourceURL.flatMap(URL.init(string:)) {
          Button { openURL(source) } label: {
            Label(text(InterfaceText.sourceCode), systemImage: "chevron.left.forwardslash.chevron.right")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(product.appStoreURL == nil ? .adaptiveGlassProminent : .adaptiveGlass)
        }
      }

      // The reliability figure, where the product it describes is. It appears
      // on the profile too, in the row of three that gives the scale; here it
      // is not a headline number but the evidence under a store button, which
      // is where somebody about to download something looks for it.
      if let metric {
        Surface(.recessed) {
          MetricTile(
            value: metric.value,
            unit: metric.unit,
            caption: metric.caption,
            countTo: metric.countTo
          )
        }
      }
    }
  }

  /// The icon and the words that name the product — written once, so the two
  /// arrangements above cannot drift apart.
  @ViewBuilder
  private var identity: some View {
    ContentImage(product.slug, kind: .appIcon)
      .frame(width: Tokens.Layout.productIconSide, height: Tokens.Layout.productIconSide)
      .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
          .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)

    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
      // The study's title and not the app's name: the name is on the icon
      // beside it, and the title is the pitch — it names the product and then
      // says what it took. That sentence was rendered nowhere except as the
      // heading of a card two tabs away.
      Text(study?.title ?? product.name)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      // The study's subtitle when there is a study, the app's own sentence
      // otherwise. Without this fallback the card of an app with no case study
      // was its name above a button, and nothing else — seen in a capture
      // before it was written down.
      if let sentence = study?.subtitle ?? product.summary {
        Text(sentence)
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

/// The four screenshots the API publishes.
///
/// They were rendered at the very bottom of a case study, two pushes from the
/// first screen, behind five collapsed chapters. They are the product.
struct ProductGalleryBlock: View {
  let media: [Media]

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: Tokens.Space.s3) {
        ForEach(media) { item in
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            ContentImage(item.id, kind: .screenshot, label: item.alt)
              .frame(height: Tokens.Layout.galleryHeight)
              .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
                  .strokeBorder(Color.line, lineWidth: Tokens.Stroke.regular)
              )
            Text(item.caption)
              .font(Typography.caption)
              .foregroundStyle(Color.ink3)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(width: Tokens.Layout.galleryHeight * Tokens.Layout.screenshotAspect)
        }
      }
      .scrollTargetLayout()
      .padding(.horizontal, Tokens.Space.s5)
    }
    .padding(.horizontal, -Tokens.Space.s5)
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
    .decision(ProductDecisions.gallery)
  }
}

/// How it was built: the problem, the decisions, the results.
///
/// The study has a single untitled chapter — one story read straight through —
/// so it is rendered as its three panels and not as a fold. A disclosure with
/// one row is a control that only ever does one thing.
struct ProductStoryBlock: View {
  let study: CaseStudy

  var body: some View {
    if let chapter = study.chapters.first {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        ForEach(CaseStudy.Panel.Kind.allCases, id: \.self) { kind in
          if let panel = chapter.panel(kind) {
            Surface {
              VStack(alignment: .leading, spacing: Tokens.Space.s3) {
                Text(panel.heading).eyebrowStyle()
                ForEach(Array(panel.prose.enumerated()), id: \.offset) { _, paragraph in
                  RichTextView(paragraph)
                }
                if !panel.tags.isEmpty {
                  WrappingRow {
                    ForEach(panel.tags, id: \.self) { Chip($0, emphasis: .accented) }
                  }
                  .padding(.top, Tokens.Space.s1)
                }
              }
            }
          }
        }
      }
      .reveal()
    }
  }
}

/// The things he wrote that are not products: a component, an exercise.
///
/// They sat in the journey, between certifications and skills, because that is
/// where a CV puts them. They belong here: this tab answers "what has he built
/// himself", and the honest answer has two tiers — what shipped, and what is
/// readable. Keeping the tiers apart is what stops an interview exercise from
/// standing next to an App Store product as though they were the same claim.
struct OpenProjectsBlock: View {
  let projects: [OpenProject]

  @Environment(\.openURL) private var openURL
  @Localized(.interface) private var text

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.openProjects)).eyebrowStyle()

      VStack(spacing: Tokens.Space.s3) {
        ForEach(projects) { project in
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
              Text(project.name)
                .font(Typography.bodyStrong)
                .foregroundStyle(Color.ink)
              RichTextView(project.description, font: Typography.secondary, color: .ink2)
              if let source = project.sourceURL.flatMap(URL.init(string:)) {
                Button { openURL(source) } label: {
                  Label(text(InterfaceText.sourceCode), systemImage: "arrow.up.right")
                }
                .buttonStyle(.adaptiveGlass)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }
}
