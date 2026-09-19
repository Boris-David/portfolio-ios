import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The journey: experience, education, certifications, open projects, skills.
///
/// ## Why this screen is a `List` and the others are not
///
/// Because its content is **rows**. Five positions, three diplomas, two
/// certifications, two projects, five skill groups — homogeneous records, each
/// a date, a name and a line of detail. It was a `ScrollView` of `VStack`s of
/// cards, which is `<div class="card">` translated into Swift, and it was the
/// single clearest reason the app read as a web page in a shell.
///
/// A `List` gives, for free and correctly: system separators and their insets,
/// section headers that stick, row metrics that hold at the accessibility text
/// sizes, and row recycling down what is the longest scroll in the app.
///
/// The rule the rest of the rebuild follows from here: **`List` when the data
/// is homogeneous and in rows** — this screen, a settings form —
/// **free composition when the content is editorial** — a case study, an essay,
/// the profile. That split is what makes the app native without making every
/// screen look the same.
public struct JourneyScreen: View {
  @Environment(PortfolioStore.self) private var store
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(.journey) {
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

    return List {
      Section {
        ForEach(Array(portfolio.experience.enumerated()), id: \.element.id) { index, job in
          ExperienceRow(
            job: job,
            dates: dates,
            startsOpen: index == 0,
            // ⚠️ The note is about **date formatting**, so it is attached to a
            // formatted date and not to the section — which is where it used
            // to be, back when an annotation was an anchor the screen
            // collected. Attached, a modifier on a `Section` is applied to
            // every row of it, so one note became three identical pins.
            //
            // And on the first row only: the mode is a demonstration, and the
            // same pin repeated down a list adds noise without adding a fact.
            annotatesDates: index == 0
          )
        }
      }

      RecordSection(
        title: text(InterfaceText.education),
        rows: portfolio.background.education.map { entry in
          RecordRow.Model(
            when: dates.years(entry.startYear, entry.endYear),
            what: entry.degree,
            detail: entry.detail.map { "\(entry.school) — \($0)" } ?? entry.school,
            link: nil
          )
        }
      )

      RecordSection(
        title: text(InterfaceText.certifications),
        rows: portfolio.background.certifications.map { entry in
          RecordRow.Model(
            when: dates.long(entry.awardedOn),
            what: entry.name,
            detail: entry.issuer,
            link: entry.verifyURL.flatMap(URL.init(string:)).map {
              RecordRow.Model.Link(label: text(InterfaceText.verifyCertificate), url: $0)
            }
          )
        }
      )

      RecordSection(
        title: text(InterfaceText.openProjects),
        rows: portfolio.background.openProjects.map { project in
          RecordRow.Model(
            when: nil,
            what: project.name,
            detail: project.description.plain,
            link: project.sourceURL.flatMap(URL.init(string:)).map {
              RecordRow.Model.Link(label: text(InterfaceText.sourceCode), url: $0)
            }
          )
        }
      )

      SkillsSection(groups: portfolio.skills, title: text(InterfaceText.skills))
    }
    .listStyle(.insetGrouped)
    // The list draws its own grouped background, which is a system grey the
    // rest of the app does not use. Hidden, so the paper shows through and the
    // rows keep their own surface.
    .scrollContentBackground(.hidden)
    // ⚠️ A `List` on iPad runs the full width of the window, and a highlight
    // then set a line **1 300 pt long** — measured on an iPad Pro 13". That is
    // the exact failure `.readableWidth()` exists for, and it had never been
    // applied to a list because until now there was no list.
    //
    // The bound goes on the list, the paper goes outside it: `readableWidth()`
    // keeps an outer full-width frame, so the background still reaches both
    // edges and only the rows are narrowed.
    .readableWidth()
    .background(Color.paper)
    .returningToTop()
    .refreshable { await store.refresh() }
  }
}

/// One position, expandable.
///
/// ## Why `DisclosureGroup` here and a hand-built fold elsewhere
///
/// The repository's rule is that folded content **stays in the view tree** at
/// zero height, so a transition starts from a state that exists. That rule is
/// about a fold built by hand, inside a card, and it still holds there — the
/// case study's chapters keep it.
///
/// In a `List` the native control wins, and for a reason that is not taste: a
/// zero-height subview inside a row fights the row's own height measurement,
/// and the separator then sits where the collapsed content used to be.
/// `DisclosureGroup` is what a list row expands with, it carries the
/// "collapsed / expanded" trait for VoiceOver on its own, and it animates
/// against the list's layout rather than against a clipped frame.
struct ExperienceRow: View {
  let job: Experience
  let dates: DateStyle
  let startsOpen: Bool
  /// Whether this row carries the annotation about how its date is written.
  /// One row does; see the call site.
  var annotatesDates = false

  @State private var isOpen: Bool?
  @ReducedMotion private var reducedMotion

  /// The most recent one is open on arrival — it is the one people came to
  /// read. `nil` means "not yet decided by the reader", which lets the initial
  /// state depend on position without freezing it.
  private var open: Binding<Bool> {
    Binding(get: { isOpen ?? startsOpen }, set: { isOpen = $0 })
  }

  var body: some View {
    DisclosureGroup(isExpanded: open.animation(reducedMotion ? nil : Motion.disclosure)) {
      VStack(alignment: .leading, spacing: Tokens.Space.s3) {
        // ⚠️ The side roles belong here and not in the label.
        //
        // `DisclosureGroup` centres its chevron against the whole label, so
        // four chips wrapping over three lines pushed the chevron down beside
        // them — it read as belonging to a chip rather than to the row. And
        // editorially they are detail: the label is when, what and where; that
        // he is also Scrum Master is part of the unfolding.
        if !job.sideRoles.isEmpty {
          WrappingRow {
            ForEach(job.sideRoles, id: \.self) { Chip($0, emphasis: .accented) }
          }
        }
        ForEach(Array(job.highlights.enumerated()), id: \.offset) { _, highlight in
          HStack(alignment: .top, spacing: Tokens.Space.s3) {
            Circle()
              .fill(Color.accent)
              .frame(width: Tokens.Layout.timelineDot, height: Tokens.Layout.timelineDot)
              .padding(.top, Tokens.Space.s2)
            RichTextView(highlight)
          }
        }
        if !job.stack.isEmpty {
          WrappingRow {
            ForEach(job.stack, id: \.self) { Chip($0) }
          }
        }
      }
      .padding(.vertical, Tokens.Space.s2)
    } label: {
      summary
    }
  }

  private var summary: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
      Text(dates.range(from: job.start, to: job.end))
        .eyebrowStyle()
        .decision(annotatesDates ? JourneyDecisions.timeline : nil)
      Text(job.role)
        .font(Typography.heading)
        .foregroundStyle(Color.ink)
        .multilineTextAlignment(.leading)
        // Served content: the source decides its length, not this file, so it
        // wraps instead of truncating. Without it the text is cut with an
        // ellipsis, and only at the accessibility sizes — which is why reading
        // the code never catches it, and a capture does.
        .fixedSize(horizontal: false, vertical: true)
      Text("\(job.organisation) · \(job.location)")
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, Tokens.Space.s1)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(job.role), \(job.organisation)")
  }
}

/// A set of homogeneous records — diplomas, certifications, open projects.
struct RecordSection: View {
  let title: String
  let rows: [RecordRow.Model]

  var body: some View {
    Section {
      ForEach(rows) { RecordRow(model: $0) }
    } header: {
      Text(title)
    }
  }
}

/// One record: when, what, who, and the way to check it.
struct RecordRow: View {
  struct Model: Identifiable {
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

  let model: Model
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
      if let when = model.when {
        Text(when)
          .font(Typography.caption)
          .foregroundStyle(Color.accent)
          .monospacedDigit()
      }
      Text(model.what)
        .font(Typography.bodyStrong)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(model.detail)
        .font(Typography.secondary)
        .foregroundStyle(Color.ink2)
        .fixedSize(horizontal: false, vertical: true)

      if let link = model.link {
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
    .padding(.vertical, Tokens.Space.s1)
  }
}

/// What he works with, by family.
///
/// ## Why the thirty-five chips went, and the content stayed
///
/// The plan said to drop this block: thirty-five pills at the bottom of the
/// longest scroll in the app, and a few of them — the older frameworks and
/// tools — argue against seniority rather than for it.
///
/// Half of that is right. The pills are gone: a pill is a filter you can tap,
/// and none of these were, so thirty-five of them were thirty-five promises
/// the screen did not keep. Five rows of plain text say the same thing in a
/// sixth of the height.
///
/// The other half is not mine to do. Removing the *display* of something the
/// API serves is exactly how `profile.remote` and `profile.showcase` came to be
/// decoded, modelled and shown to nobody — the defect this whole rebuild exists
/// to fix. If an item argues against him, it is an editorial change at the
/// source, where the content is decided and where the website would see it too.
struct SkillsSection: View {
  let groups: [SkillGroup]
  let title: String

  var body: some View {
    Section {
      ForEach(groups) { group in
        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
          Text(group.title)
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
          Text(group.items.joined(separator: " · "))
            .font(Typography.secondary)
            .foregroundStyle(Color.ink2)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Tokens.Space.s1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.title): \(group.items.joined(separator: ", "))")
      }
    } header: {
      Text(title)
    }
  }
}
