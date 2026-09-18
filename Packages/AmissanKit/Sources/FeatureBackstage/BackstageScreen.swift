import Backstage
import DesignSystem
import Domain
import FeatureKit
import SwiftUI
import Textual

/// Les coulisses de l'application elle-même.
///
/// Un portfolio qui montre des écrans montre un résultat. Cet onglet montre les
/// **décisions** — et une décision se juge à ce qu'elle a écarté autant qu'à ce
/// qu'elle a retenu.
public struct BackstageScreen: View {
  @Environment(BackstageController.self) private var backstage
  @Chrome private var chrome

  public init() {}

  public var body: some View {
    SectionShell(title: chrome.tabBackstage) {
      ScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s7) {
          intro
          LayersBlock()
          ChallengesBlock()
          WalkthroughsBlock()
          DependenciesBlock()
        }
        .padding(.bottom, Tokens.Space.s8)
      }
    }
  }

  private var intro: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      SectionHeader(
        eyebrow: chrome.backstageEyebrow,
        title: chrome.backstageTitle,
        intro: chrome.backstageIntro
      )

      Toggle(isOn: Binding(
        get: { backstage.isEnabled },
        set: { _ in backstage.toggle() }
      )) {
        Label(chrome.backstageToggle, systemImage: "number.circle")
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
        Text(PlatformCapabilities.summary)
          .font(Typography.caption)
      }
      .foregroundStyle(Color.ink3)
    }
    .padding(.horizontal, Tokens.Space.s5)
    .padding(.top, Tokens.Space.s4)
  }
}

/// Les couches, et ce que chacune n'a **pas** le droit de connaître.
struct LayersBlock: View {
  @Chrome private var chrome
  @Environment(\.contentLanguage) private var language
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(chrome.architecture).eyebrowStyle()
      InlineMarkdown(chrome.architectureIntro)

      VStack(spacing: Tokens.Space.s3) {
        ForEach(AppDossier.layers) { layer in
          Surface {
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
              HStack(alignment: .firstTextBaseline) {
                Text(layer.name)
                  .font(Typography.code)
                  .foregroundStyle(Color.accent)
                Spacer(minLength: Tokens.Space.s2)
                if layer.dependsOn.isEmpty {
                  Chip(chrome.noDependency, emphasis: .accented)
                }
              }
              InlineMarkdown(
                layer.responsibility(language),
                font: Typography.bodyStrong,
                color: .ink
              )
              StructuredText(markdown: layer.rule(language))
                .font(Typography.secondary)
                .foregroundStyle(Color.ink2)
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

/// Les défis, dépliables.
struct ChallengesBlock: View {
  @Chrome private var chrome
  @Environment(\.contentLanguage) private var language
  @State private var opened: Set<String> = []
  @ReducedMotion private var reducedMotion

  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(chrome.challenges).eyebrowStyle()

      VStack(spacing: Tokens.Space.s3) {
        ForEach(AppDossier.challenges) { challenge in
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
              .accessibilityValue(opened.contains(challenge.id) ? chrome.expanded : chrome.collapsed)

              VStack(alignment: .leading, spacing: Tokens.Space.s4) {
                Divider().overlay(Color.line)
                labelled(chrome.theProblem, challenge.problem(language))
                labelled(chrome.theSolution, challenge.solution(language))
                labelled(chrome.theLesson, challenge.lesson(language))
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
      StructuredText(markdown: markdown)
        .font(Typography.body)
        .foregroundStyle(Color.ink2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Les chaînes de bout en bout : qui fait quoi, dans l'ordre.
struct WalkthroughsBlock: View {
  @Chrome private var chrome
  @Environment(\.contentLanguage) private var language
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(chrome.endToEnd).eyebrowStyle()

      ForEach(AppDossier.walkthroughs) { walkthrough in
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
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.onAccent)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.accent))
                  VStack(alignment: .leading, spacing: 1) {
                    Text(step.actor)
                      .font(Typography.code)
                      .foregroundStyle(Color.accent)
                    StructuredText(markdown: step.does(language))
                      .font(Typography.secondary)
                      .foregroundStyle(Color.ink2)
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

/// Les dépendances : celles qu'on prend, celles qu'on refuse, et pourquoi.
struct DependenciesBlock: View {
  @Chrome private var chrome
  @Environment(\.contentLanguage) private var language
  var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s4) {
      Text(chrome.dependencies).eyebrowStyle()
      InlineMarkdown(chrome.dependenciesRule)

      ForEach(AppDossier.dependencies) { call in
        Surface {
          VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s2) {
              Text(call.name)
                .font(Typography.heading)
                .foregroundStyle(Color.ink)
              Spacer(minLength: Tokens.Space.s2)
              verdict(call.verdict)
            }
            StructuredText(markdown: call.reasoning(language))
              .font(Typography.secondary)
              .foregroundStyle(Color.ink2)
          }
        }
      }
    }
    .padding(.horizontal, Tokens.Space.s5)
    .reveal()
  }

  @ViewBuilder
  private func verdict(_ verdict: AppDossier.DependencyCall.Verdict) -> some View {
    switch verdict {
    case .adopted(let version):
      Label(version, systemImage: "checkmark.circle.fill")
        .font(Typography.caption)
        .foregroundStyle(Color.ok)
    case .declined:
      Label(chrome.declined, systemImage: "minus.circle")
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
    }
  }
}
