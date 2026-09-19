import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The decisions of the app itself.
///
/// A portfolio that shows screens shows a result. This screen shows the
/// **decisions** — and a decision is judged by what it ruled out as much as by
/// what it kept.
///
/// ## Why it stopped being a tab
///
/// A tab is a destination somebody returns to. Nobody returns to a list of
/// architecture decisions: they read it once, if at all, and they read it
/// because a project made them curious. Pushed from the work tab, it is one tap
/// from what raises the question — and the slot it gave up went to the one
/// thing the app was not showing, a product you can install.
public struct EngineeringScreen: View {
  @Environment(SettingsStore.self) private var settings
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionScrollView {
      VStack(alignment: .leading, spacing: Tokens.Space.s7) {
        intro
        LayersBlock()
        // Straight after the layers of *this* app: the same question, asked of
        // the codebases behind the career.
        ReadingLinkRow(
          route: .architectures,
          title: text(InterfaceText.architecturePatterns),
          summary: text(InterfaceText.architecturePatternsSummary)
        )
        ChallengesBlock()
        WalkthroughsBlock()
        DependenciesBlock()
      }
      .padding(.top, Tokens.Space.s4)
    }
    .background(Color.paper)
    // ⚠️ The **short** form in the bar, and the long one in the content.
    //
    // It was the long one, and it came out truncated mid-word in the one place
    // the title appeared at all, because the content had given up its copy. An
    // inline navigation title takes about thirty characters; anything longer
    // stays in the content, which can wrap.
    .navigationTitle(text(InterfaceText.engineeringEyebrow))
    .navigationBarTitleDisplayMode(.inline)
  }

  private var intro: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      // No eyebrow: the navigation bar carries the short form, which is
      // exactly what an eyebrow is, and printing it twice thirty points apart
      // says nothing the second time.
      Text(text(InterfaceText.engineeringTitle))
        .font(Typography.title)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(text(InterfaceText.engineeringIntro))
        .font(Typography.body)
        .foregroundStyle(Color.ink2)
        .fixedSize(horizontal: false, vertical: true)

      Toggle(isOn: Binding(
        get: { settings.showsDecisions },
        set: { value in Task { await settings.setShowsDecisions(value) } }
      )) {
        Label(text(InterfaceText.decisionsToggle), icon: .annotations)
          .font(Typography.bodyStrong)
      }
      .tint(Color.accent)
      .padding(Tokens.Space.s4)
      .background(
        RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
          .fill(Color.accentWash)
      )

      HStack(spacing: Tokens.Space.s2) {
        Image(systemName: PlatformCapabilities.supportsLiquidGlass ? "sparkles" : "square.stack")
          .font(.footnote)
        Text(text(PlatformCapabilities.supportsLiquidGlass ? InterfaceText.renderingLiquidGlass : InterfaceText.renderingFallback))
          .font(Typography.caption)
      }
      .foregroundStyle(Color.ink3)
    }
  }
}

/// The layers, and what each one is **not** allowed to know.
struct LayersBlock: View {
  @Localized(.interface) private var text
  @Localized(.engineering) private var record
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.architecture)).eyebrowStyle()
      InlineMarkdown(text(InterfaceText.architectureIntro))

      VStack(spacing: Tokens.Space.s3) {
        ForEach(EngineeringRecord.layers) { layer in
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
              HStack(alignment: .firstTextBaseline) {
                Text(layer.name)
                  .font(Typography.code)
                  .foregroundStyle(Color.accent)
                Spacer(minLength: Tokens.Space.s2)
                if layer.dependsOn.isEmpty {
                  Chip(text(InterfaceText.noDependency), emphasis: .accented)
                }
              }
              InlineMarkdown(
                record(layer.responsibilityKey),
                font: Typography.bodyStrong,
                color: .ink
              )
              MarkdownText(record(layer.ruleKey), font: Typography.secondary, color: .ink2)
              if !layer.dependsOn.isEmpty {
                WrappingRow {
                  ForEach(layer.dependsOn, id: \.self) { Chip($0) }
                }
              }
            }
          }
        }
      }
    }
    .reveal()
  }
}

/// The challenges, expandable.
struct ChallengesBlock: View {
  @Localized(.interface) private var text
  @Localized(.engineering) private var record
  @State private var opened: Set<String> = []
  @ReducedMotion private var reducedMotion

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.challenges)).eyebrowStyle()

      VStack(spacing: Tokens.Space.s3) {
        ForEach(EngineeringRecord.challenges) { challenge in
          Surface(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
              Button {
                withAnimation(reducedMotion ? nil : Motion.disclosure) {
                  if opened.contains(challenge.id) {
                    opened.remove(challenge.id)
                  } else {
                    opened.insert(challenge.id)
                  }
                }
              } label: {
                HStack(alignment: .top, spacing: Tokens.Space.s3) {
                  Text(record(challenge.titleKey))
                    .font(Typography.heading)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                  Spacer(minLength: 0)
                  Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.ink3)
                    .rotationEffect(.degrees(opened.contains(challenge.id) ? 0 : -90))
                    .padding(.top, 4)
                }
                .padding(Tokens.Space.s4)
                .contentShape(Rectangle())
              }
              .buttonStyle(.pressableCard)
              .accessibilityAddTraits(.isButton)
              .accessibilityValue(opened.contains(challenge.id) ? text(InterfaceText.expanded) : text(InterfaceText.collapsed))

              VStack(alignment: .leading, spacing: Tokens.Space.s4) {
                Divider().overlay(Color.line)
                labelled(text(InterfaceText.theProblem), record(challenge.problemKey))
                labelled(text(InterfaceText.theSolution), record(challenge.solutionKey))
                labelled(text(InterfaceText.theLesson), record(challenge.lessonKey))
              }
              .padding(.horizontal, Tokens.Space.s4)
              .padding(.bottom, Tokens.Space.s4)
              .frame(height: opened.contains(challenge.id) ? nil : 0, alignment: .top)
              .opacity(opened.contains(challenge.id) ? 1 : 0)
              .clipped()
              .accessibilityHidden(!opened.contains(challenge.id))
            }
          }
        }
      }
    }
    .reveal()
  }

  private func labelled(_ title: String, _ markdown: String) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(title).eyebrowStyle()
      MarkdownText(markdown, font: Typography.body, color: .ink2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The end-to-end walkthroughs: who does what, in order.
struct WalkthroughsBlock: View {
  @Localized(.interface) private var text
  @Localized(.engineering) private var record
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.endToEnd)).eyebrowStyle()

      ForEach(EngineeringRecord.walkthroughs) { walkthrough in
        Surface {
          VStack(alignment: .leading, spacing: Tokens.Space.s3) {
            Text(record(walkthrough.titleKey))
              .font(Typography.heading)
              .foregroundStyle(Color.ink)
            InlineMarkdown(record(walkthrough.summaryKey), font: Typography.secondary)

            VStack(alignment: .leading, spacing: Tokens.Space.s3) {
              ForEach(Array(walkthrough.components.enumerated()), id: \.offset) { index, component in
                HStack(alignment: .top, spacing: Tokens.Space.s3) {
                  Text("\(index + 1)")
                    .font(.system(size: Tokens.Icon.badge, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.onAccent)
                    .frame(width: Tokens.Layout.stepBadge, height: Tokens.Layout.stepBadge)
                    .background(Circle().fill(Color.accent))
                  VStack(alignment: .leading, spacing: 1) {
                    Text(component)
                      .font(Typography.code)
                      .foregroundStyle(Color.accent)
                    MarkdownText(record(walkthrough.stepKey(index + 1)), font: Typography.secondary, color: .ink2)
                  }
                }
                .accessibilityElement(children: .combine)
              }
            }
            .padding(.top, Tokens.Space.s1)
          }
        }
      }
    }
    .reveal()
  }
}

/// The dependencies: the ones taken, the ones declined, and why.
struct DependenciesBlock: View {
  @Localized(.interface) private var text
  @Localized(.engineering) private var record
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.dependencies)).eyebrowStyle()
      InlineMarkdown(text(InterfaceText.dependenciesRule))

      ForEach(EngineeringRecord.dependencies) { decision in
        Surface {
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s2) {
              Text(decision.name)
                .font(Typography.heading)
                .foregroundStyle(Color.ink)
              Spacer(minLength: Tokens.Space.s2)
              outcome(decision.outcome)
            }
            MarkdownText(record(decision.reasoningKey), font: Typography.secondary, color: .ink2)
          }
        }
      }
    }
    .reveal()
  }

  @ViewBuilder
  private func outcome(_ outcome: EngineeringRecord.DependencyDecision.Outcome) -> some View {
    switch outcome {
    case .adopted(let version):
      Label(version, systemImage: "checkmark.circle.fill")
        .font(Typography.caption)
        .foregroundStyle(Color.ok)
    case .declined:
      Label(text(InterfaceText.declined), systemImage: "minus.circle")
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
    }
  }
}
