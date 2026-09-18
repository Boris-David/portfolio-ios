import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Presentation
import SwiftUI
import ViewKit

/// The decision of the app itself.
///
/// A portfolio that shows screens shows a result. This tab shows the
/// **decisions** — and a decision is judged by what it ruled out as much as by
/// what it kept.
public struct EngineeringScreen: View {
  @Environment(SettingsStore.self) private var settings
  @Localized(.interface) private var text

  public init() {}

  public var body: some View {
    SectionShell(title: text(InterfaceText.tabEngineering)) {
      ScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s7) {
          intro
          LayersBlock()
          // Straight after the layers of *this* app: the same question, asked of
          // the codebases behind the career.
          ArchitectureLinkRow()
          ChallengesBlock()
          WalkthroughsBlock()
          DependenciesBlock()
        }
        .padding(.bottom, Tokens.Space.s8)
        .readableWidth()
      }
    }
  }

  private var intro: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      SectionHeader(
        eyebrow: text(InterfaceText.engineeringEyebrow),
        title: text(InterfaceText.engineeringTitle),
        intro: text(InterfaceText.engineeringIntro)
      )

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
    .padding(.horizontal, Tokens.Space.s5)
    .padding(.top, Tokens.Space.s4)
  }
}

/// The layers, and what each one is **not** allowed to know.
struct LayersBlock: View {
  @Localized(.interface) private var text
  @Environment(\.contentLanguage) private var language
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
                layer.responsibility(language),
                font: Typography.bodyStrong,
                color: .ink
              )
              MarkdownText(layer.rule(language), font: Typography.secondary, color: .ink2)
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
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

/// The challenges, expandable.
struct ChallengesBlock: View {
  @Localized(.interface) private var text
  @Environment(\.contentLanguage) private var language
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
                  Text(challenge.title(language))
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
              .buttonStyle(.plain)
              .accessibilityAddTraits(.isButton)
              .accessibilityValue(opened.contains(challenge.id) ? text(InterfaceText.expanded) : text(InterfaceText.collapsed))

              VStack(alignment: .leading, spacing: Tokens.Space.s4) {
                Divider().overlay(Color.line)
                labelled(text(InterfaceText.theProblem), challenge.problem(language))
                labelled(text(InterfaceText.theSolution), challenge.solution(language))
                labelled(text(InterfaceText.theLesson), challenge.lesson(language))
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
    .padding(.horizontal, Tokens.Space.s5)
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
  @Environment(\.contentLanguage) private var language
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.endToEnd)).eyebrowStyle()

      ForEach(EngineeringRecord.walkthroughs) { walkthrough in
        Surface {
          VStack(alignment: .leading, spacing: Tokens.Space.s3) {
            Text(walkthrough.title(language))
              .font(Typography.heading)
              .foregroundStyle(Color.ink)
            InlineMarkdown(walkthrough.summary(language), font: Typography.secondary)

            VStack(alignment: .leading, spacing: Tokens.Space.s3) {
              ForEach(Array(walkthrough.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Tokens.Space.s3) {
                  Text("\(index + 1)")
                    .font(.system(size: Tokens.Icon.badge, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.onAccent)
                    .frame(width: Tokens.Layout.stepBadge, height: Tokens.Layout.stepBadge)
                    .background(Circle().fill(Color.accent))
                  VStack(alignment: .leading, spacing: 1) {
                    Text(step.actor)
                      .font(Typography.code)
                      .foregroundStyle(Color.accent)
                    MarkdownText(step.does(language), font: Typography.secondary, color: .ink2)
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
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }
}

/// The dependencies: the ones taken, the ones declined, and why.
struct DependenciesBlock: View {
  @Localized(.interface) private var text
  @Environment(\.contentLanguage) private var language
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(text(InterfaceText.dependencies)).eyebrowStyle()
      InlineMarkdown(text(InterfaceText.dependenciesRule))

      ForEach(EngineeringRecord.dependencies) { call in
        Surface {
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s2) {
              Text(call.name)
                .font(Typography.heading)
                .foregroundStyle(Color.ink)
              Spacer(minLength: Tokens.Space.s2)
              verdict(call.verdict)
            }
            MarkdownText(call.reasoning(language), font: Typography.secondary, color: .ink2)
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }

  @ViewBuilder
  private func verdict(_ verdict: EngineeringRecord.DependencyCall.Verdict) -> some View {
    switch verdict {
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
