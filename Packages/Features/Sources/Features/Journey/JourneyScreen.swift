import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The journey: experience, education, certifications, skills.
public struct JourneyScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(title: text(InterfaceText.tabJourney)) {
      // The four phases are rendered in one place, by one component.
      // No screen rewrites this switch: that is what makes them all behave
      // alike — same skeleton, same transition, same failure screen.
      PhaseView(store.phase, retry: { store.load() }) { snapshot in
        content(snapshot.portfolio)
      }
    }
  }

  private func content(_ portfolio: Portfolio) -> some View {
    let dates = DateStyle(language: store.language)

    return ScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        if let section = portfolio.section("background") {
          SectionHeader(eyebrow: section.eyebrow, title: section.title)
            .padding(.horizontal, Tokens.Space.s5)
        }

        VStack(spacing: Tokens.Space.s3) {
          ForEach(Array(portfolio.experience.enumerated()), id: \.element.id) { index, job in
            ExperienceCard(job: job, dates: dates, startsOpen: index == 0)
          }
        }
        .padding(.horizontal, Tokens.Space.s5)
        .decision(JourneyDecisions.timeline)

        TimelineBlock(
          title: text(InterfaceText.education),
          rows: portfolio.background.education.map { entry in
            TimelineEntry(
              when: dates.years(entry.startYear, entry.endYear),
              what: entry.degree,
              detail: entry.detail.map { "\(entry.school) — \($0)" } ?? entry.school,
              link: nil
            )
          }
        )

        TimelineBlock(
          title: text(InterfaceText.certifications),
          rows: portfolio.background.certifications.map { entry in
            TimelineEntry(
              when: dates.long(entry.awardedOn),
              what: entry.name,
              detail: entry.issuer,
              link: entry.verifyURL.flatMap(URL.init(string:)).map {
                TimelineEntry.Link(label: text(InterfaceText.verifyCertificate), url: $0)
              }
            )
          }
        )

        TimelineBlock(
          title: text(InterfaceText.openProjects),
          rows: portfolio.background.openProjects.map { project in
            TimelineEntry(
              when: nil,
              what: project.name,
              detail: project.description.plain,
              link: project.sourceURL.flatMap(URL.init(string:)).map {
                TimelineEntry.Link(label: text(InterfaceText.sourceCode), url: $0)
              }
            )
          }
        )

        SkillsBlock(groups: portfolio.skills)
      }
      .padding(.top, Tokens.Space.s4)
      .padding(.bottom, Tokens.Space.s8)
      .readableWidth()
    }
    .refreshable { await store.refresh() }
  }

}

/// One position, expandable.
struct ExperienceCard: View {
  let job: Experience
  let dates: DateStyle
  let startsOpen: Bool

  @State private var isOpen: Bool?
  @ReducedMotion private var reducedMotion
  @Localized(.interface) private var text

  /// The most recent one is open on arrival — it is the one people came to
  /// read. `nil` means "not yet decided by the reader", which lets the initial
  /// state depend on position without freezing it.
  private var open: Bool { isOpen ?? startsOpen }

  var body: some View {
    Surface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        header
        details
      }
    }
  }

  private var header: some View {
    Button {
      withAnimation(reducedMotion ? nil : Motion.disclosure) { isOpen = !open }
    } label: {
      VStack(alignment: .leading, spacing: Tokens.Space.s2) {
        HStack(alignment: .top) {
          Text(dates.range(from: job.start, to: job.end)).eyebrowStyle()
          Spacer(minLength: Tokens.Space.s2)
          Image(systemName: "chevron.down")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.ink3)
            .rotationEffect(.degrees(open ? 0 : -90))
        }
        Text(job.role)
          .font(Typography.heading)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.leading)
          // Served content: the source decides its length, not this file, so
          // it wraps instead of truncating. Without it the text is cut with an
          // ellipsis, and only at the accessibility sizes — which is why
          // reading the code never catches it, and a capture does.
          .fixedSize(horizontal: false, vertical: true)
        Text("\(job.organisation) · \(job.location)")
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)

        if !job.sideRoles.isEmpty {
          WrappingRow {
            ForEach(job.sideRoles, id: \.self) { Chip($0, emphasis: .accented) }
          }
          .padding(.top, Tokens.Space.s1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Tokens.Space.s4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.pressableCard)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("\(job.role), \(job.organisation)")
    .accessibilityValue(open ? text(InterfaceText.expanded) : text(InterfaceText.collapsed))
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Divider().overlay(Color.line)
      ForEach(Array(job.highlights.enumerated()), id: \.offset) { _, highlight in
        HStack(alignment: .top, spacing: Tokens.Space.s3) {
          Circle()
            .fill(Color.accent)
            .frame(width: Tokens.Layout.timelineDot, height: Tokens.Layout.timelineDot)
            .padding(.top, 8)
          RichTextView(highlight)
        }
      }
      if !job.stack.isEmpty {
        WrappingRow {
          ForEach(job.stack, id: \.self) { Chip($0) }
        }
        .padding(.top, Tokens.Space.s2)
      }
    }
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.bottom, Tokens.Space.s4)
    .frame(height: open ? nil : 0, alignment: .top)
    .opacity(open ? 1 : 0)
    .clipped()
    .accessibilityHidden(!open)
  }
}

/// One timeline row — education, certification, project.
struct TimelineEntry: Identifiable {
  struct Link {
    let label: String
    let url: URL
  }

  var id: String { what }
  let when: String?
  let what: String
  let detail: String
  let link: Link?
}

struct TimelineBlock: View {
  let title: String
  let rows: [TimelineEntry]
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(title).eyebrowStyle()
      VStack(spacing: Tokens.Space.s3) {
        ForEach(rows) { row in
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s1) {
              if let when = row.when {
                Text(when)
                  .font(Typography.caption)
                  .foregroundStyle(Color.accent)
                  .monospacedDigit()
              }
              Text(row.what)
                .font(Typography.bodyStrong)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
              Text(row.detail)
                .font(Typography.secondary)
                .foregroundStyle(Color.ink2)
                .fixedSize(horizontal: false, vertical: true)
              if let link = row.link {
                Button {
                  openURL(link.url)
                } label: {
                  Label(link.label, systemImage: "checkmark.seal")
                    .font(Typography.caption)
                }
                .buttonStyle(.pressableCard)
                .foregroundStyle(Color.accent)
                .padding(.top, Tokens.Space.s1)
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

struct SkillsBlock: View {
  let groups: [SkillGroup]
  @Localized(.interface) private var text

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.skills)).eyebrowStyle()
      ForEach(groups) { group in
        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
          Text(group.title)
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
          WrappingRow {
            ForEach(group.items, id: \.self) { Chip($0) }
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}
