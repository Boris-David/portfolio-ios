import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import SwiftUI
import ViewKit

/// A case study in full.
///
/// Two layouts for one model, told apart by a property of the **narrative** and
/// not by a technical field: a chapter with a title is a piece of work that can
/// be named and unfolded; an untitled chapter is the single body of one story,
/// read straight through.
public struct CaseStudyDetailScreen: View {
  private let study: CaseStudy
  @Environment(\.openURL) private var openURL

  public init(study: CaseStudy) {
    self.study = study
  }

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s5) {
        header

        if study.hasNamedChapters {
          VStack(spacing: Tokens.Space.s3) {
            ForEach(Array(study.chapters.enumerated()), id: \.element.id) { index, chapter in
              // The first one is **open**. A page of five closed rows is a page
              // where nothing has been said yet: the reader has to guess which
              // one is worth a tap before anything has earned one. Opening the
              // first shows what a chapter contains, and the rest stay closed
              // so the page is still scannable.
              ChapterDisclosureView(
                number: index + 1,
                chapter: chapter,
                startsOpen: index == 0
              )
            }
          }
          .decision(WorkDecisions.disclosure)
        } else if let chapter = study.chapters.first {
          FlatChapterView(chapter: chapter)
        }

        if !study.media.isEmpty {
          GalleryView(media: study.media)
        }

        WrappingRow {
          ForEach(study.tags, id: \.self) { Chip($0) }
        }
      }
      .padding(.top, Tokens.Space.s4)
    }
    .background(Color.paper)
    .navigationTitle(study.title)
    // ⚠️ `.inline`, and the content keeps its own copy of the title. That looks
    // like a duplication and it was tried the other way round.
    //
    // `.large` with the content title removed said it once — and **truncated
    // it to one line**: *"La billettique mobile…"*. A UIKit large title does
    // not wrap, so a title of any length simply stops, and the full one then
    // appeared nowhere in the app. Measured on screen; nothing in the build
    // says a word about it.
    //
    // So the bar carries the short form for the back button and VoiceOver, the
    // content carries the whole thing, and that is what every Apple app with a
    // long title does.
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(study.subtitle).eyebrowStyle()
      Text(study.title)
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let intro = study.intro {
        RichTextView(intro)
      }
      if let link = study.link {
        Button {
          if let url = URL(string: link.url) { openURL(url) }
        } label: {
          Label(link.label, systemImage: "arrow.up.right")
        }
        .buttonStyle(.adaptiveGlass)
        .padding(.top, Tokens.Space.s1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

}

/// One expandable piece of work.
struct ChapterDisclosureView: View {
  let number: Int
  let chapter: CaseStudy.Chapter

  @State private var isOpen: Bool
  @ReducedMotion private var reducedMotion
  @Localized(.interface) private var text

  init(number: Int, chapter: CaseStudy.Chapter, startsOpen: Bool = false) {
    self.number = number
    self.chapter = chapter
    _isOpen = State(initialValue: startsOpen)
  }

  var body: some View {
    Surface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        summary
        body_
      }
    }
  }

  private var summary: some View {
    Button {
      withAnimation(reducedMotion ? nil : Motion.disclosure) { isOpen.toggle() }
    } label: {
      HStack(alignment: .top, spacing: Tokens.Space.s3) {
        Text(String(format: "%02d", number))
          .font(Typography.code)
          .foregroundStyle(Color.accent)
          .monospacedDigit()

        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
          Text(chapter.title ?? "")
            .font(Typography.bodyStrong)
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
          // ⚠️ The subtitle is where the **result** is written — *"un code
          // hérité que personne ne voulait toucher, refondu avec des
          // acteurs"*, *"une initiative devenue une fonctionnalité vendue"* —
          // and it was set 13 pt in `ink3`, the treatment for a footnote.
          //
          // So five rows read as a list of bugs: "the authentication that
          // logged people out", "the QR code fraud". The content was never the
          // problem; the hierarchy was. Raised, the same five rows are five
          // results, and a reader who opens none of them has still had them.
          if let subtitle = chapter.subtitle {
            Text(subtitle)
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        Spacer(minLength: Tokens.Space.s2)

        Image(systemName: "chevron.down")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(Color.ink3)
          .rotationEffect(.degrees(isOpen ? 0 : -90))
          .padding(.top, 2)
      }
      .padding(Tokens.Space.s4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.pressableCard)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(chapter.title ?? "")
    .accessibilityValue(isOpen ? text(InterfaceText.expanded) : text(InterfaceText.collapsed))
    
  }

  /// The body stays in the view tree even when collapsed — only its height
  /// drops to zero. That is what keeps the text findable by system search and
  /// reachable by VoiceOver, and what lets the transition start from a state
  /// that exists.
  private var body_: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Divider().overlay(Color.line)
      ForEach(CaseStudy.Panel.Kind.allCases, id: \.self) { kind in
        if let panel = chapter.panel(kind) {
          PanelView(panel: panel)
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s4)
    .padding(.bottom, Tokens.Space.s4)
    .frame(height: isOpen ? nil : 0, alignment: .top)
    .opacity(isOpen ? 1 : 0)
    // Without clipping, the collapsed content spills over the next card for
    // the whole animation.
    .clipped()
    .accessibilityHidden(!isOpen)
  }
}

/// A story read straight through — three stacked columns.
struct FlatChapterView: View {
  let chapter: CaseStudy.Chapter

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s5) {
      ForEach(CaseStudy.Panel.Kind.allCases, id: \.self) { kind in
        if let panel = chapter.panel(kind) {
          Surface { PanelView(panel: panel) }
        }
      }
    }
  }
}

/// A panel: its heading, its body, its chips.
struct PanelView: View {
  let panel: CaseStudy.Panel

  var body: some View {
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
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The screenshots, scrolling horizontally.
struct GalleryView: View {
  let media: [Media]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Tokens.Space.s3) {
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
        }
      }
      .scrollTargetLayout()
    }
    // Scrolling settles on a screenshot, never between two: a gallery that
    // stops straddling looks broken.
    .scrollTargetBehavior(.viewAligned)
    .scrollClipDisabled()
  }
}
