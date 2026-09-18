import Backstage
import CoreUI
import DesignSystem
import Domain
import FeatureKit
import Foundation
import Presentation
import SwiftUI
import ViewKit

/// Appearance, language, backstage — and a way back to the defaults.
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
  @Environment(\.contentLanguage) private var language
  @Environment(\.dismiss) private var dismiss

  @State private var isConfirmingReset = false

  public init() {}

  private var chrome: SettingsChrome { .for(language) }

  public var body: some View {
    NavigationStack {
      Form {
        appearanceSection
        languageSection
        backstageSection
        resetSection
      }
      .navigationTitle(chrome.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(chrome.done) { dismiss() }
        }
      }
      // The haptic is tied to the value that changed, not to the tap: it cannot
      // fire before the preference was actually written.
      .feedback(.selectionChanged, on: settings.appearance)
      .feedback(.selectionChanged, on: settings.language)
      .feedback(.selectionChanged, on: settings.isBackstageEnabled)
      .backstage(Self.formNote)
    }
    // A settings sheet is a short task, and the screen underneath is worth
    // keeping in view: it is what the reader is about to see change.
    .presentationDetents([.large])
  }

  // ── Appearance ─────────────────────────────────────────────────────────

  private var appearanceSection: some View {
    Section {
      Picker(chrome.appearanceSection, selection: appearanceBinding) {
        Text(chrome.appearanceSystem).tag(AppearancePreference.system)
        Text(chrome.appearanceLight).tag(AppearancePreference.light)
        Text(chrome.appearanceDark).tag(AppearancePreference.dark)
      }
      .pickerStyle(.segmented)
      .backstage(Self.pickerNote)
    } header: {
      Label(chrome.appearanceSection, icon: .appearance)
    } footer: {
      InlineMarkdown(chrome.appearanceNote, font: Typography.caption, color: .ink3)
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
      Picker(chrome.languageSection, selection: languageBinding) {
        Text(chrome.languageSystem).tag(LanguagePreference.system)
        Text(chrome.languageFrench).tag(LanguagePreference.fixed(.french))
        Text(chrome.languageEnglish).tag(LanguagePreference.fixed(.english))
      }
      .pickerStyle(.inline)
      .labelsHidden()
    } header: {
      Label(chrome.languageSection, icon: .language)
    } footer: {
      InlineMarkdown(chrome.languageNote, font: Typography.caption, color: .ink3)
    }
  }

  private var languageBinding: Binding<LanguagePreference> {
    Binding(
      get: { settings.language },
      set: { value in Task { await settings.setLanguage(value) } }
    )
  }

  // ── Backstage ──────────────────────────────────────────────────────────

  private var backstageSection: some View {
    Section {
      Toggle(chrome.backstageToggle, isOn: backstageBinding)
    } header: {
      Label(chrome.backstageSection, icon: .annotations)
    } footer: {
      InlineMarkdown(chrome.backstageNote, font: Typography.caption, color: .ink3)
    }
  }

  private var backstageBinding: Binding<Bool> {
    Binding(
      get: { settings.isBackstageEnabled },
      set: { value in Task { await settings.setBackstageEnabled(value) } }
    )
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  private var resetSection: some View {
    Section {
      Button(role: .destructive) {
        isConfirmingReset = true
      } label: {
        Label(chrome.reset, icon: .reset)
      }
      // A confirmation dialog and not an alert: an alert is for a choice that
      // cannot be undone, and this one can — you simply set them again. The
      // dialog also rises from the button, which keeps the connection between
      // what was tapped and what is being asked.
      .confirmationDialog(
        chrome.resetQuestion,
        isPresented: $isConfirmingReset,
        titleVisibility: .visible
      ) {
        Button(chrome.resetConfirm, role: .destructive) {
          Task {
            await settings.reset()
            toasts.show(chrome.resetDone, kind: .succeeded, icon: .succeeded)
          }
        }
        Button(chrome.resetCancel, role: .cancel) {}
      }
      .backstage(Self.confirmationNote)
    } header: {
      Text(chrome.resetSection)
    }
  }

  // ── Backstage ──────────────────────────────────────────────────────────

  static let formNote = BackstageNote(
    id: "settings.form",
    component: "Form · Section",
    role: Bilingual(
      fr: "Donne à cet écran la forme des Réglages du système.",
      en: "Gives this screen the shape of the system's own Settings."
    ),
    rationale: Bilingual(
      fr: """
        Un écran de réglages qui ne ressemble pas à celui d'iOS fait travailler \
        le lecteur pour rien. `Form` apporte le regroupement, les marges, le \
        retrait des séparateurs, l'évitement du clavier et le comportement en \
        Dynamic Type — autant de détails qu'on redérive à l'œil et qu'on rate \
        subtilement.
        """,
      en: """
        A settings screen that does not look like the system's makes the reader \
        work for nothing. `Form` brings the grouping, the insets, the separator \
        inset, keyboard avoidance and the Dynamic Type behaviour — all details \
        otherwise re-derived by eye and got subtly wrong.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une `List` et des lignes maison", en: "A `List` with hand-built rows"),
        because: Bilingual(
          fr: "Il faut alors refaire les en-têtes, les bas de section et les marges — et ils dérivent à chaque version d'iOS.",
          en: "You then rebuild headers, footers and insets — and they drift with every iOS release."
        )
      ),
      .init(
        Bilingual(fr: "Un cinquième onglet", en: "A fifth tab"),
        because: Bilingual(
          fr: "Un onglet est une destination de contenu. Les réglages s'ouvrent, se changent, se referment.",
          en: "A tab is a content destination. Settings open, change one thing, and close."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Dès qu'un écran est une liste de préférences. Pas pour de la mise en page libre, où `Form` impose sa structure.",
      en: "Whenever a screen is a list of preferences. Not for free-form layout, where `Form` imposes its structure."
    ),
    pitfall: Bilingual(
      fr: "`Form` applique ses propres marges : y poser un conteneur déjà espacé produit un décalage qu'on cherche ensuite dans le mauvais fichier.",
      en: "`Form` applies its own insets: putting an already-padded container inside produces an offset you then hunt in the wrong file."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/form")
  )

  static let pickerNote = BackstageNote(
    id: "settings.picker",
    component: "Picker · .segmented",
    role: Bilingual(
      fr: "Trois apparences, toutes visibles, une seule choisie.",
      en: "Three appearances, all visible, one chosen."
    ),
    rationale: Bilingual(
      fr: """
        Un segmenté se justifie à **trois choix courts et mutuellement \
        exclusifs** : tout est lisible d'un coup d'œil, et le choix se fait en \
        un geste. Au-delà de quatre, les libellés se tronquent et le contrôle \
        devient une devinette.
        """,
      en: """
        A segmented control earns its place at **three short, mutually \
        exclusive choices**: everything is legible at a glance, and choosing \
        takes one gesture. Past four, the labels truncate and the control \
        becomes a guessing game.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Un `Menu` déroulant", en: "A pull-down `Menu`"),
        because: Bilingual(
          fr: "Il cache les options : on ne sait ce qu'on peut choisir qu'après avoir tapé.",
          en: "It hides the options: you only learn what you can choose after tapping."
        )
      ),
      .init(
        Bilingual(fr: "Un `Toggle` clair/sombre", en: "A light/dark `Toggle`"),
        because: Bilingual(
          fr: "Deux états ne peuvent pas exprimer « suivre l'appareil », qui est le défaut et une valeur à part entière.",
          en: "Two states cannot express “follow the device”, which is the default and a value in its own right."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Deux à quatre options courtes qu'on veut toutes montrer. La langue, juste en dessous, emploie une liste : les libellés y sont des noms de langues, et ils s'allongent.",
      en: "Two to four short options you want all visible. Language, just below, uses a list instead: its labels are language names, and they grow."
    ),
    pitfall: Bilingual(
      fr: "Les libellés ne se tronquent pas gracieusement en Dynamic Type extra-large : ils se chevauchent. À vérifier à l'écran, pas au jugé.",
      en: "The labels do not truncate gracefully at extra-large Dynamic Type: they overlap. Check it on screen, not by eye."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/picker")
  )

  static let confirmationNote = BackstageNote(
    id: "settings.confirmation",
    component: "confirmationDialog",
    role: Bilingual(
      fr: "Demande confirmation avant de remettre les réglages à zéro.",
      en: "Asks before putting the settings back to their defaults."
    ),
    rationale: Bilingual(
      fr: """
        `alert` et `confirmationDialog` ne disent pas la même chose. Une \
        **alerte** interrompt pour un choix qu'on ne pourra pas défaire ; un \
        **dialogue de confirmation** propose des options, monte depuis le \
        bouton qui l'a déclenché, et se referme d'un geste vers le bas.
        """,
      en: """
        `alert` and `confirmationDialog` do not say the same thing. An **alert** \
        interrupts for a choice that cannot be undone; a **confirmation \
        dialog** offers options, rises from the button that triggered it, and \
        dismisses with a swipe.
        """
    ),
    rejected: [
      .init(
        Bilingual(fr: "Une `alert`", en: "An `alert`"),
        because: Bilingual(
          fr: "Réinitialiser trois préférences se défait en trois gestes. Une alerte pour ça apprend au lecteur à les ignorer.",
          en: "Resetting three preferences is undone in three gestures. An alert for that teaches the reader to dismiss them."
        )
      ),
      .init(
        Bilingual(fr: "Aucune confirmation", en: "No confirmation at all"),
        because: Bilingual(
          fr: "Un bouton destructif atteint par erreur doit pouvoir être rattrapé avant, pas après.",
          en: "A destructive button reached by accident has to be catchable before, not after."
        )
      ),
    ],
    whenToUse: Bilingual(
      fr: "Un choix entre plusieurs options, ou une action destructive réversible. Au-delà de trois boutons, c'est un écran.",
      en: "A choice between several options, or a reversible destructive action. Past three buttons, it is a screen."
    ),
    pitfall: Bilingual(
      fr: "Sur iPad il se rend en popover ancré à la source : sans source identifiable, il apparaît au centre et on ne sait plus ce qu'il concerne.",
      en: "On iPad it renders as a popover anchored to its source: with no identifiable source it appears centred, and nobody knows what it refers to."
    ),
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:)")
  )
}
