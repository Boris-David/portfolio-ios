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
/// The one fact the app did not say: where he is, and what he is open to. The
/// accented line held the remote-working sentence for a while, under a house —
/// and the author's reading of it was flat: *"my home is the French Riviera,
/// rather"*. The house names the place, and what he is open to is the line
/// under it, where the rest of the quiet facts already live.
struct IdentityBlock: View {
  let profile: Profile
  @Environment(\.openRoute) private var openRoute
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

      placeLine
      quietFacts
      aboutLink
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .decision(ProfileDecisions.hero)
  }

  /// Where he is — the one fact given colour, under the one icon.
  ///
  /// Not a floating pill: the author's verdict on the badge this replaced was
  /// *"that's web, that's AI-generated"*. A line of accented text says the same
  /// thing without borrowing a landing page's vocabulary.
  private var placeLine: some View {
    Label {
      Text(profile.location)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(Icon.remote)
    }
    .font(Typography.bodyStrong)
    .foregroundStyle(Color.accent)
    .accessibilityElement(children: .combine)
  }

  /// What he is open to, and in which languages, as **one line of text**.
  ///
  /// They were three rows with icons — the shape a landing page uses to fill a
  /// column. On a phone they are one sentence. The place has moved up to the
  /// accented line, so it is not repeated here: `availability` now carries the
  /// remote arrangement, which is what a reader filters on after knowing where.
  private var quietFacts: some View {
    Text([profile.availability, profile.languages].joined(separator: " · "))
      .font(Typography.caption)
      .foregroundStyle(Color.ink3)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityLabel([profile.availability, profile.languages].joined(separator: ", "))
  }

  private var aboutLink: some View {
    Button { openRoute(.about) } label: {
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

/// The publishable figures, and only those.
///
/// ## Why they are stacked again, and it is not a step back
///
/// They were three cards of 383 pt, which put `6 ans` and `> 99,9 %` below the
/// fold on the screen whose job is to establish scale in three seconds. A row
/// of three fixed that, and it fixed it for a caption of three words.
///
/// The captions are now sentences — the author's own, read aloud rather than
/// labelled — and a third of a phone screen cannot carry one: about 26
/// characters a line, where justified prose needs forty. So the figures stay
/// one statement, read down instead of across, and each sentence gets the
/// whole column.
///
/// What is gone is the **cards**, which is what made the first version cost
/// 383 pt. One recessed surface holds the three, and no figure sits below the
/// fold.
struct MetricsBlock: View {
  let metrics: [Metric]

  var body: some View {
    Surface(.recessed) {
      VStack(alignment: .leading, spacing: Tokens.Space.s5) {
        ForEach(metrics) { MetricRow($0) }
      }
    }
    .reveal()
    .decision(ProfileDecisions.metrics)
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
  @Environment(\.openRoute) private var openRoute
  @Localized(.interface) private var text

  var body: some View {
    if let slug = showcase.caseStudySlug {
      Button { openRoute(.caseStudy(slug: slug)) } label: { card }
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

          // `description` says what the product does; `media.alt` describes
          // the picture for somebody who cannot see it, and is passed to the
          // image above. They were the same string until 2026-09-20, so the
          // sentence a sighted reader took as a pitch was also the one
          // VoiceOver read as a description of a screenshot.
          ProseView(showcase.description, role: .secondary)

          // ⚠️ No `Spacer` above this. There was one, pinning the link to the
          // bottom of a card whose height is set by the screenshot beside it —
          // which opened a band of nothing between the description and the way
          // in. Invisible on a phone, where the text happens to fill the
          // column; obvious on iPad, where it does not.
          if showcase.caseStudySlug != nil {
            HStack(spacing: Tokens.Space.s2) {
              Text(text(InterfaceText.learnMore))
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
  @Environment(\.openRoute) private var openRoute

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
          openRoute(.expertise(id: topic.id))
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

/// The contact card, at the foot of the profile.
///
/// A `Surface` around the shared card and nothing else: what a contact *is* is
/// decided in one place, and this decides where it sits. It is the last block
/// of the scroll on purpose — the action comes after the argument.
struct ContactBlock: View {
  let contact: Profile.Contact

  var body: some View {
    Surface {
      ContactCard(contact: contact)
    }
    .reveal()
    .decision(ProfileDecisions.action)
  }
}
