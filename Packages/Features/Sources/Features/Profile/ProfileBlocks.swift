import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The opening: who he is, what he is open to, and where he will work from.
///
/// ## What it stopped being, and why
///
/// It was a 72 pt monogram, an animated signature stroke, the name, the role, a
/// quiet line of facts, a "contact me" button and a link — 106 pt of decoration
/// before the first fact, on the screen that decides whether anybody reads the
/// rest.
///
/// A monogram is what you put when you have neither a photograph nor a product.
/// He has thirty-five products. They are two blocks down this screen now, and
/// the space they took came from here.
///
/// The "contact me" button left as well. It asked for a decision on the sixth
/// line of the app, before there was anything to decide about, and the same
/// action sits at the bottom of this very scroll where it belongs — after the
/// argument, not before it.
///
/// ## What arrived
///
/// `profile.remote` — *"opportunités de télétravail complet et fréquent"*. It
/// was decoded, modelled, carried through three layers and **displayed by
/// nobody**. It is the first thing a recruiter filters on, and it was the one
/// fact the app did not say.
struct IdentityBlock: View {
  let profile: Profile
  @Localized(.interface) private var text

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(profile.name.display)
        .font(Typography.hero)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)

      Text(profile.headline)
        .font(Typography.bodyStrong)
        .foregroundStyle(Color.ink2)
        // ⚠️ Truncates rather than wraps without this, and only at the
        // accessibility sizes: "Ingénieur iOS senior" came out as "Ingénieur
        // iOS s…" — the one line on the first screen that says what he does.
        .fixedSize(horizontal: false, vertical: true)

      remoteLine
      quietFacts
      aboutLink
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .decision(ProfileDecisions.hero)
  }

  /// The reader's first filter, and therefore the one fact given colour.
  ///
  /// Not a floating pill: the author's verdict on the badge this replaced was
  /// *"that's web, that's AI-generated"*. A line of accented text says the same
  /// thing without borrowing a landing page's vocabulary.
  private var remoteLine: some View {
    Label {
      Text(profile.remote)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(Icon.remote)
    }
    .font(Typography.bodyStrong)
    .foregroundStyle(Color.accent)
    .accessibilityElement(children: .combine)
  }

  /// Availability, location and languages as **one line of text**.
  ///
  /// They were three rows with icons — the shape a landing page uses to fill a
  /// column. On a phone they are one sentence, read in the order somebody
  /// actually needs them: is he available, where, in which languages.
  private var quietFacts: some View {
    Text([profile.availability, profile.location, profile.languages].joined(separator: " · "))
      .font(Typography.caption)
      .foregroundStyle(Color.ink3)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityLabel(
        [profile.availability, profile.location, profile.languages].joined(separator: ", ")
      )
  }

  private var aboutLink: some View {
    NavigationLink(value: Route.about) {
      HStack(spacing: Tokens.Space.s2) {
        Text(text(InterfaceText.aboutLink))
        Image(systemName: "arrow.right")
          .font(.system(size: Tokens.Icon.caption, weight: .semibold))
      }
      .font(Typography.secondary)
      .foregroundStyle(Color.accent)
    }
    .padding(.top, Tokens.Space.s1)
  }
}

/// The publishable figures, and only those — side by side.
///
/// ## Why they stopped being three stacked cards
///
/// Because they were **383 pt** of scroll for three numbers, which put `6 ans`
/// and `> 99,8 %` below the fold on the screen whose job is to establish scale
/// in three seconds. Read as a row they are one statement — a portfolio's
/// headline figures — instead of three separate claims each asking for its own
/// attention.
///
/// The captions gained a size and a shade in the move: they were 13 pt `ink3`,
/// which is the treatment for a footnote, on the sentence that says what each
/// number *means*.
struct MetricsBlock: View {
  let metrics: [Metric]
  @Environment(\.dynamicTypeSize) private var typeSize

  var body: some View {
    Surface(.recessed) {
      // ⚠️ A threshold, and not `ViewThatFits` — which is what the rest of this
      // codebase reaches for first, and which cannot work here. It picks the
      // first candidate whose **ideal** size fits, and a wrapping caption's
      // ideal width is its whole unwrapped sentence. The row would never be
      // chosen at any size. `isAccessibilitySize` is a semantic threshold, not
      // a number somebody guessed at.
      if typeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: Tokens.Space.s5) {
          tiles
        }
      } else {
        HStack(alignment: .top, spacing: Tokens.Space.s4) {
          tiles
        }
      }
    }
    .reveal()
    .decision(ProfileDecisions.metrics)
  }

  @ViewBuilder
  private var tiles: some View {
    ForEach(metrics) { metric in
      MetricTile(
        value: metric.value,
        unit: metric.unit,
        caption: metric.caption,
        countTo: metric.countTo
      )
    }
  }
}

/// The app he took end to end, shown rather than claimed.
///
/// ## Why this block had to exist
///
/// `profile.showcase` was served by the API, decoded, modelled, and its image
/// was sitting in the bundle — and **nothing rendered it**. The application of
/// an iOS engineer carried no screenshot of an application anywhere near its
/// first screen. That is the single most obvious thing such an app can show,
/// and it was the one thing missing.
struct ShowcaseBlock: View {
  let showcase: Profile.Showcase
  @Localized(.interface) private var text

  var body: some View {
    if let slug = showcase.caseStudySlug {
      NavigationLink(value: Route.caseStudy(slug: slug)) { card }
        .buttonStyle(.pressableCard)
        .zoomSource(slug)
    } else {
      // A showcase published without its study still shows the product. The
      // card simply stops being a way in.
      card
    }
  }

  private var card: some View {
    Surface(.raised, padding: Tokens.Space.s4) {
      HStack(alignment: .top, spacing: Tokens.Space.s4) {
        ContentImage(showcase.media.id, kind: .screenshot, label: showcase.media.alt)
          .frame(height: Tokens.Layout.showcaseHeight)
          .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
              .strokeBorder(Color.line, lineWidth: Tokens.Stroke.hairline)
          )

        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
          Text(showcase.media.caption)
            .font(Typography.heading)
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

          Text(showcase.media.alt)
            .font(Typography.secondary)
            .foregroundStyle(Color.ink2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

          // ⚠️ No `Spacer` above this. There was one, pinning the link to the
          // bottom of a card whose height is set by the screenshot beside it —
          // which opened a band of nothing between the description and the way
          // in. Invisible on a phone, where the text happens to fill the
          // column; obvious on iPad, where it does not.
          if showcase.caseStudySlug != nil {
            HStack(spacing: Tokens.Space.s2) {
              Text(text(InterfaceText.readStudy))
              Image(systemName: "arrow.right")
                .font(.caption2.weight(.semibold))
            }
            .font(Typography.caption)
            .foregroundStyle(Color.accent)
            .padding(.top, Tokens.Space.s1)
          }

          Spacer(minLength: 0)
        }
      }
    }
    .reveal()
  }
}

/// The three subjects dug into.
struct ExpertiseBlock: View {
  let section: Portfolio.Section?
  let topics: [ExpertiseTopic]
  @Environment(Router.self) private var router

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      if let section {
        SectionHeader(
          eyebrow: section.eyebrow,
          title: section.title,
          intro: section.intro?.plain
        )
      }
      ForEach(topics) { topic in
        Button {
          router.push(.expertise(id: topic.id))
        } label: {
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
              HStack {
                Text(topic.title)
                  .font(Typography.heading)
                  .foregroundStyle(Color.ink)
                  .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Tokens.Space.s3)
                Image(systemName: "chevron.right")
                  .font(.footnote.weight(.semibold))
                  .foregroundStyle(Color.ink3)
              }
              Text(topic.body.plain)
                .font(Typography.secondary)
                .foregroundStyle(Color.ink2)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            }
          }
        }
        .buttonStyle(.pressableCard)
      }
    }
    .reveal()
  }
}

/// The one published contact channel.
struct ContactBlock: View {
  let contact: Profile.Contact
  @Environment(\.openURL) private var openURL

  var body: some View {
    Surface {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        Text(contact.title)
          .font(Typography.title)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(contact.body)
          .font(Typography.body)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)

        Button {
          if let url = URL(string: "mailto:\(contact.email)") { openURL(url) }
        } label: {
          Label(contact.email, icon: .contact)
        }
        .buttonStyle(.adaptiveGlassProminent)
        .decision(ProfileDecisions.action)

        WrappingRow {
          ForEach(contact.links) { link in
            Button {
              if let url = URL(string: link.url) { openURL(url) }
            } label: {
              Label(link.label, systemImage: symbol(for: link.id))
                .font(Typography.secondary)
            }
            .buttonStyle(.adaptiveGlass)
          }
        }
      }
    }
    .reveal()
  }

  /// SF Symbols does not cover brands: GitHub and LinkedIn are not in it.
  /// Rather than embedding logos — whose use their owners govern — a generic
  /// symbol is used, and the **label** carries the identification.
  private func symbol(for id: String) -> String {
    switch id {
    case "github": "chevron.left.forwardslash.chevron.right"
    case "linkedin": "person.2"
    default: "link"
    }
  }
}
