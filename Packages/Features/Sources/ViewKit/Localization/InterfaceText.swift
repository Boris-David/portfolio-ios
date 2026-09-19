import Domain
import Localization
import Presentation

/// The keys for the labels the interface itself owns: tabs, actions, states,
/// section headings.
///
/// ## Why these are keys and not sentences
///
/// A sentence needs a bundle, a compiled catalogue and the language on screen —
/// three delivery details. Naming a key needs none of them, so the layers below
/// the view can decide *which* label applies without being able to write one:
/// `AppSection` hands back a case, `ContentUnavailable` hands back a value, and
/// the mapping to a key lives here, in the view layer, beside the catalogue.
///
/// Every value is in `Resources/Localizable.xcstrings`, and editing one never
/// opens a Swift file.
package enum InterfaceText {
  package static let aboutLink: TextKey = "interface.aboutLink"
  package static let aboutTitle: TextKey = "interface.aboutTitle"
  package static let architecture: TextKey = "interface.architecture"
  package static let architectureIntro: TextKey = "interface.architectureIntro"
  package static let architecturePatterns: TextKey = "interface.architecturePatterns"
  package static let architecturePatternsSummary: TextKey = "interface.architecturePatternsSummary"
  package static let certifications: TextKey = "interface.certifications"
  package static let challenges: TextKey = "interface.challenges"
  package static let close: TextKey = "interface.close"
  package static let codebases: TextKey = "interface.codebases"
  package static let collapsed: TextKey = "interface.collapsed"
  package static let comparison: TextKey = "interface.comparison"
  package static let contactAction: TextKey = "interface.contactAction"
  package static let contactTitle: TextKey = "interface.contactTitle"
  package static let copyLink: TextKey = "interface.copyLink"
  package static let decisionsToggle: TextKey = "interface.decisionsToggle"
  package static let declined: TextKey = "interface.declined"
  package static let dependencies: TextKey = "interface.dependencies"
  package static let dependenciesRule: TextKey = "interface.dependenciesRule"
  package static let education: TextKey = "interface.education"
  package static let endToEnd: TextKey = "interface.endToEnd"
  package static let engineeringEyebrow: TextKey = "interface.engineeringEyebrow"
  package static let engineeringIntro: TextKey = "interface.engineeringIntro"
  package static let engineeringTitle: TextKey = "interface.engineeringTitle"
  package static let expanded: TextKey = "interface.expanded"
  package static let linkCopied: TextKey = "interface.linkCopied"
  package static let loading: TextKey = "interface.loading"
  package static let noDependency: TextKey = "interface.noDependency"
  package static let nothingAvailableMessage: TextKey = "interface.nothingAvailableMessage"
  package static let openInAppStore: TextKey = "interface.openInAppStore"
  package static let openProjects: TextKey = "interface.openProjects"
  package static let provenanceHint: TextKey = "interface.provenanceHint"
  package static let provenanceTitle: TextKey = "interface.provenanceTitle"
  package static let provenanceVersion: TextKey = "interface.provenanceVersion"
  package static let readStudy: TextKey = "interface.readStudy"
  package static let resumeAction: TextKey = "interface.resumeAction"
  package static let resumeLoading: TextKey = "interface.resumeLoading"
  package static let resumeReady: TextKey = "interface.resumeReady"
  package static let resumeTitle: TextKey = "interface.resumeTitle"
  package static let retry: TextKey = "interface.retry"
  package static let revalidated: TextKey = "interface.revalidated"
  package static let routeMissingMessage: TextKey = "interface.routeMissingMessage"
  package static let routeMissingTitle: TextKey = "interface.routeMissingTitle"
  package static let separatesLabel: TextKey = "interface.separatesLabel"
  package static let settings: TextKey = "interface.settings"
  package static let share: TextKey = "interface.share"
  package static let skills: TextKey = "interface.skills"
  package static let sourceCode: TextKey = "interface.sourceCode"
  package static let tabEngineering: TextKey = "interface.tabEngineering"
  package static let tabJourney: TextKey = "interface.tabJourney"
  package static let tabProfile: TextKey = "interface.tabProfile"
  package static let tabWork: TextKey = "interface.tabWork"
  package static let theLesson: TextKey = "interface.theLesson"
  package static let theProblem: TextKey = "interface.theProblem"
  package static let theSolution: TextKey = "interface.theSolution"
  package static let unavailableTitle: TextKey = "interface.unavailableTitle"
  package static let unreachableMessage: TextKey = "interface.unreachableMessage"
  package static let unreadableTitle: TextKey = "interface.unreadableTitle"
  package static let verifyCertificate: TextKey = "interface.verifyCertificate"
  package static let whatTheFilesShow: TextKey = "interface.whatTheFilesShow"
  package static let whenToUse: TextKey = "interface.whenToUse"

  // ── What used to be a function with a `language ==` in its body ──────────
  //
  // Each of these took the language as an argument and picked a sentence with a
  // ternary. The catalogue does it better: the plural rule below belongs to the
  // language, and written by hand it produced "1 chantiers".

  /// Varies by plural. Read with `text(InterfaceText.chapterCount, count: n)`.
  package static let chapterCount: TextKey = "interface.chapterCount"
  /// Takes the date, already formatted.
  package static let verifiedOn: TextKey = "interface.verifiedOn"
  /// Takes the date, already formatted.
  package static let countsTakenOn: TextKey = "interface.countsTakenOn"
  /// Takes the field path, then the reason — in that order in French and in
  /// English, and a language needing the other order says so in the catalogue.
  package static let malformed: TextKey = "interface.malformed"
  package static let malformedMissingField: TextKey = "interface.malformed.missingField"
  package static let malformedUnexpectedType: TextKey = "interface.malformed.unexpectedType"
  package static let malformedNullValue: TextKey = "interface.malformed.nullValue"
  package static let malformedWrongLanguage: TextKey = "interface.malformed.wrongLanguage"
  package static let malformedUnknownValue: TextKey = "interface.malformed.unknownValue"
  package static let malformedUnreadableDate: TextKey = "interface.malformed.unreadableDate"
  package static let malformedMonthOutOfRange: TextKey = "interface.malformed.monthOutOfRange"
  package static let malformedUnacceptableFileName: TextKey = "interface.malformed.unacceptableFileName"
  package static let malformedInsecureURL: TextKey = "interface.malformed.insecureURL"
  package static let criterionBuys: TextKey = "interface.criterion.buys"
  package static let criterionCosts: TextKey = "interface.criterion.costs"
  package static let criterionChooseWhen: TextKey = "interface.criterion.chooseWhen"
  package static let criterionBreaksWhere: TextKey = "interface.criterion.breaksWhere"
  package static let renderingLiquidGlass: TextKey = "interface.rendering.liquidGlass"
  package static let renderingFallback: TextKey = "interface.rendering.fallback"
  package static let depthEyebrow: TextKey = "interface.depthEyebrow"
  package static let provenTitle: TextKey = "interface.provenTitle"
  package static let provenLink: TextKey = "interface.provenLink"
  package static let tipTitle: TextKey = "interface.tip.title"
  package static let tipMessage: TextKey = "interface.tip.message"
}

/// The keys for the settings screen.
///
/// Separate from `InterfaceText` because they are read by one screen, and a
/// catalogue everything reads is a catalogue nobody dares delete from.
package enum SettingsText {
  package static let appearanceDark: TextKey = "settings.appearanceDark"
  package static let appearanceLight: TextKey = "settings.appearanceLight"
  package static let appearanceNote: TextKey = "settings.appearanceNote"
  package static let appearanceSection: TextKey = "settings.appearanceSection"
  package static let appearanceSystem: TextKey = "settings.appearanceSystem"
  package static let decisionsToggle: TextKey = "settings.decisionsToggle"
  package static let designDecision: TextKey = "settings.designDecision"
  package static let done: TextKey = "settings.done"
  package static let engineeringSection: TextKey = "settings.engineeringSection"
  package static let languageEnglish: TextKey = "settings.languageEnglish"
  package static let languageFrench: TextKey = "settings.languageFrench"
  package static let languageNote: TextKey = "settings.languageNote"
  package static let languageSection: TextKey = "settings.languageSection"
  package static let languageSystem: TextKey = "settings.languageSystem"
  package static let reset: TextKey = "settings.reset"
  package static let resetCancel: TextKey = "settings.resetCancel"
  package static let resetConfirm: TextKey = "settings.resetConfirm"
  package static let resetDone: TextKey = "settings.resetDone"
  package static let resetQuestion: TextKey = "settings.resetQuestion"
  package static let resetSection: TextKey = "settings.resetSection"
  package static let title: TextKey = "settings.title"
}

extension AppSection {
  /// The key that labels this tab.
  ///
  /// The enum itself names no text — a case carrying its own string would carry
  /// it in one language, and somebody would have to remember on the day a second
  /// one is added. It names a case; this names a key; the catalogue holds the
  /// word.
  package var titleKey: TextKey {
    switch self {
    case .profile: InterfaceText.tabProfile
    case .work: InterfaceText.tabWork
    case .journey: InterfaceText.tabJourney
    case .decision: InterfaceText.tabEngineering
    }
  }
}

extension ArchitecturePattern.Criterion {
  /// The key that labels this column.
  ///
  /// The **questions** belong to the domain — dropping one would change what the
  /// comparison claims, not how it looks. Their wording belongs to the
  /// catalogue, and this is the join between the two.
  package var labelKey: TextKey {
    switch self {
    case .buys: InterfaceText.criterionBuys
    case .costs: InterfaceText.criterionCosts
    case .chooseWhen: InterfaceText.criterionChooseWhen
    case .breaksWhen: InterfaceText.criterionBreaksWhere
    }
  }
}
