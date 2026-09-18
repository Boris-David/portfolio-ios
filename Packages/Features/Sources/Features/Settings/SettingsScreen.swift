import Decisions
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// Appearance, language, decision — and a way back to the defaults.
///
/// ## Why a sheet and not a fifth tab
///
/// A tab is a **destination**: somewhere you go and come back to, that holds
/// content. Settings is neither — you open it, change one thing, and leave. Made
/// a tab, it would sit in the bar competing for attention with the three things
/// this app exists to show, and it would break the rule that a tab bar holds
/// three to five *content* destinations.
///
/// ## Why a `Form` and not hand-built rows
///
/// Because a settings screen that does not look like iOS's settings screen makes
/// the reader do work for nothing. `Form` brings the grouping, the insets, the
/// separator inset, the keyboard avoidance and the Dynamic Type behaviour that
/// would otherwise be re-derived by eye and got subtly wrong.
public struct SettingsScreen: View {
  @Environment(SettingsStore.self) private var settings
  @Environment(ToastCenter.self) private var toasts
  @Localized(.interface) private var text
  @Environment(\.dismiss) private var dismiss

  @State private var isConfirmingReset = false

  public init() {}


  public var body: some View {
    NavigationStack {
      Form {
        appearanceSection
        languageSection
        engineeringSection
        resetSection
      }
      .navigationTitle(text(SettingsText.title))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(text(SettingsText.done)) { dismiss() }
        }
      }
      // The haptic is tied to the value that changed, not to the tap: it cannot
      // fire before the preference was actually written.
      .feedback(.selectionChanged, on: settings.appearance)
      .feedback(.selectionChanged, on: settings.language)
      .feedback(.selectionChanged, on: settings.showsDecisions)
      .decision(SettingsDecisions.form)
    }
    // A settings sheet is a short task, and the screen underneath is worth
    // keeping in view: it is what the reader is about to see change.
    .presentationDetents([.large])
  }

  // ── Appearance ─────────────────────────────────────────────────────────

  private var appearanceSection: some View {
    Section {
      Picker(text(SettingsText.appearanceSection), selection: appearanceBinding) {
        Text(text(SettingsText.appearanceSystem)).tag(AppearancePreference.system)
        Text(text(SettingsText.appearanceLight)).tag(AppearancePreference.light)
        Text(text(SettingsText.appearanceDark)).tag(AppearancePreference.dark)
      }
      .pickerStyle(.segmented)
      .decision(SettingsDecisions.picker)
    } header: {
      Label(text(SettingsText.appearanceSection), icon: .appearance)
    } footer: {
      InlineMarkdown(text(SettingsText.appearanceNote), font: Typography.caption, color: .ink3)
    }
  }

  private var appearanceBinding: Binding<AppearancePreference> {
    Binding(
      get: { settings.appearance },
      set: { value in Task { await settings.setAppearance(value) } }
    )
  }

  // ── Language ───────────────────────────────────────────────────────────

  private var languageSection: some View {
    Section {
      // ⚠️ `.labelsHidden()` and not an empty label: an inline picker renders
      // its own label as a first row, so the section header "Language" appeared
      // twice, one line apart. An empty `Text("")` would have left the row in
      // place, blank — which is worse, and which is what it looked like before
      // anyone read it on screen.
      //
      // The label still exists for VoiceOver, which is the whole reason to hide
      // it rather than remove it.
      Picker(text(SettingsText.languageSection), selection: languageBinding) {
        Text(text(SettingsText.languageSystem)).tag(LanguagePreference.system)
        Text(text(SettingsText.languageFrench)).tag(LanguagePreference.fixed(.french))
        Text(text(SettingsText.languageEnglish)).tag(LanguagePreference.fixed(.english))
      }
      .pickerStyle(.inline)
      .labelsHidden()
    } header: {
      Label(text(SettingsText.languageSection), icon: .language)
    } footer: {
      InlineMarkdown(text(SettingsText.languageNote), font: Typography.caption, color: .ink3)
    }
  }

  private var languageBinding: Binding<LanguagePreference> {
    Binding(
      get: { settings.language },
      set: { value in Task { await settings.setLanguage(value) } }
    )
  }
  private var engineeringSection: some View {
    Section {
      Toggle(text(SettingsText.decisionsToggle), isOn: decisionsBinding)
    } header: {
      Label(text(SettingsText.engineeringSection), icon: .annotations)
    } footer: {
      InlineMarkdown(text(SettingsText.designDecision), font: Typography.caption, color: .ink3)
    }
  }

  private var decisionsBinding: Binding<Bool> {
    Binding(
      get: { settings.showsDecisions },
      set: { value in Task { await settings.setShowsDecisions(value) } }
    )
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  private var resetSection: some View {
    Section {
      Button(role: .destructive) {
        isConfirmingReset = true
      } label: {
        Label(text(SettingsText.reset), icon: .reset)
      }
      // A confirmation dialog and not an alert: an alert is for a choice that
      // cannot be undone, and this one can — you simply set them again. The
      // dialog also rises from the button, which keeps the connection between
      // what was tapped and what is being asked.
      .confirmationDialog(
        text(SettingsText.resetQuestion),
        isPresented: $isConfirmingReset,
        titleVisibility: .visible
      ) {
        Button(text(SettingsText.resetConfirm), role: .destructive) {
          Task {
            await settings.reset()
            toasts.show(text(SettingsText.resetDone), kind: .succeeded, icon: .succeeded)
          }
        }
        Button(text(SettingsText.resetCancel), role: .cancel) {}
      }
      .decision(SettingsDecisions.confirmation)
    } header: {
      Text(text(SettingsText.resetSection))
    }
  }
}
