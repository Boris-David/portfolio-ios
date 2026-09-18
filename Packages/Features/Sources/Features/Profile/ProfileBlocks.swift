import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The opening: a monogram, a name, one action.
///
/// ## What it stopped being, and why
///
/// It was a green-dotted pill reading "Open to opportunities", three
/// icon-and-text lines, and two buttons side by side. The owner's verdict was
/// exact: *"that's web, that's AI-generated."* And it is — that is the
/// vocabulary of a landing page, where a visitor arrives cold and has to be sold
/// something in one viewport.
///
/// An app opens differently. Somebody who launched it already decided to look;
/// the first screen owes them an **identity**, not a pitch. So: a monogram to
/// land the eye, the name, the signature, the role in one line, and **one**
/// primary action. The availability is a quiet line of text where it belongs,
/// not a floating badge demanding to be read first.
///
/// The long introduction moved to `AboutScreen`, one tap away. An opening gives
/// the scale; the story is for whoever wants it.
///
/// ## Why `ZStack` here and not anywhere else
///
/// Three genuine layers: a wash that bleeds behind the monogram, the content,
/// and the safe area. They overlap on purpose — a `VStack` would stack them,
/// which is the opposite of what is wanted. Used because it is the right tool,
/// not to have used it.
struct HeroBlock: View {
  let profile: Profile
  @Environment(Router.self) private var router
  @Environment(\.dynamicTypeSize) private var typeSize
  @ReducedMotion private var reducedMotion
  @Localized(.interface) private var text

  private var monogram: Monogram { Monogram(profile.name) }

  var body: some View {
    ZStack(alignment: .top) {
      wash
      content
    }
    .decision(ProfileDecisions.hero)
  }

  /// A soft accent glow behind the monogram, bleeding past the reading column.
  ///
  /// Decorative, therefore hidden from VoiceOver and ignored for hit testing —
  /// a gradient that swallowed taps meant for the button underneath would be a
  /// defect nobody could see.
  private var wash: some View {
    RadialGradient(
      colors: [Color.accentWash.opacity(Tokens.Opacity.heroWash), Color.paper.opacity(0)],
      center: .top,
      startRadius: 0,
      endRadius: Tokens.Layout.heroWashRadius
    )
    .frame(height: Tokens.Layout.heroWashRadius)
    // Bleeds under the navigation bar rather than starting at it: a gradient
    // that begins exactly at a bar edge draws a visible band, which reads as a
    // seam. Only visible on screen.
    .ignoresSafeArea(edges: .top)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      identityCard
      availabilityLine
      primaryAction
      aboutLink
    }
    .padding(.horizontal, Tokens.Space.s5)
    .padding(.top, Tokens.Space.s6)
  }

  // ── The card ───────────────────────────────────────────────────────────

  /// ## Why `ViewThatFits`
  ///
  /// At the accessibility text sizes, a monogram beside a name stops fitting —
  /// the name wraps to three lines and the two columns fight over the width.
  /// `ViewThatFits` takes the stacked arrangement instead, and it does so by
  /// **measuring**, not by comparing against a size threshold somebody guessed.
  private var identityCard: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .center, spacing: Tokens.Space.s4) {
        monogramBadge
        nameAndRole
      }
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        monogramBadge
        nameAndRole
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(profile.name.full). \(profile.headline)")
  }

  private var monogramBadge: some View {
    Text(monogram.letters)
      .font(.system(size: Tokens.Icon.feature, weight: .semibold, design: .serif))
      .foregroundStyle(Color.accent)
      .frame(width: Tokens.Layout.monogramSide, height: Tokens.Layout.monogramSide)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
          .fill(Color.accentWash)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous)
          .strokeBorder(Color.accent.opacity(Tokens.Opacity.annotation), lineWidth: Tokens.Stroke.hairline)
      )
      .accessibilityHidden(true)
  }

  private var nameAndRole: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
      Text(profile.name.display)
        .font(Typography.hero)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)

      // The stroke draws under the name: a signature, not a decoration. It is
      // **decorative** in the accessibility sense — VoiceOver has nothing to
      // say about it — so it is hidden rather than announced as "image".
      LottieAnimation("signature", bundle: .coreUI)
        .frame(height: Tokens.Layout.signatureHeight)
        .frame(maxWidth: Tokens.Layout.signatureWidth, alignment: .leading)
        .accessibilityHidden(true)

      Text(profile.headline)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
    }
  }

  // ── The quiet facts ────────────────────────────────────────────────────

  /// Availability, location and languages as **one line of text**.
  ///
  /// They were three rows with icons — the shape a landing page uses to fill a
  /// column. On a phone they are one sentence, read in the order somebody
  /// actually needs them: is he available, where, in which languages.
  private var availabilityLine: some View {
    Text([profile.availability, profile.location, profile.languages].joined(separator: " · "))
      .font(Typography.caption)
      .foregroundStyle(Color.ink3)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityLabel(
        [profile.availability, profile.location, profile.languages].joined(separator: ", ")
      )
  }

  // ── One action, and one way in ─────────────────────────────────────────

  /// ## Why one button and not two
  ///
  /// Two equal buttons side by side is a page asking the reader to choose before
  /// they know anything. One primary action decides for them; the résumé is a
  /// permanent toolbar item on every screen, which is both more findable and
  /// less loud.
  private var primaryAction: some View {
    Button {
      router.present(.contact)
    } label: {
      Label(text(InterfaceText.contactAction), icon: .contact)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.adaptiveGlassProminent)
    .decision(ProfileDecisions.action)
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
  }
}

/// The publishable figures, and only those.
struct MetricsBlock: View {
  let metrics: [Metric]

  var body: some View {
    VStack(spacing: Tokens.Space.s4) {
      ForEach(metrics) { metric in
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
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
    .decision(ProfileDecisions.metrics)
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
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

/// A subject's detail.
struct ExpertiseDetailView: View {
  let topic: ExpertiseTopic

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s4) {
        Text(topic.title)
          .font(Typography.title)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)
        RichTextView(topic.body)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s5)
    }
    .background(Color.paper)
    .navigationTitle(topic.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// The one published contact channel.
struct ContactBlock: View {
  let contact: Profile.Contact
  @Environment(\.openURL) private var openURL

  var body: some View {
    Surface(.raised) {
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
          Label(contact.email, systemImage: "envelope")
        }
        .buttonStyle(.adaptiveGlassProminent)

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
    .padding(.horizontal, Tokens.Space.s5)
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
