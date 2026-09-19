import Domain
import Presentation

/// Turns a failure into the keys that word it.
///
/// ## Why this mapping lives in exactly one place
///
/// It did not, and the cost was visible: `PortfolioStore` translated
/// `.nothingAvailable` to an empty-tray icon while a second copy of the same
/// `switch`, written inside a view, translated it to a crossed-out wifi symbol.
/// The same failure looked like two different failures depending on which screen
/// you were standing on — and neither was wrong on its own, which is why nobody
/// noticed. Duplicated presentation logic does not announce itself by breaking;
/// it announces itself by drifting.
///
/// ## Why it lives here rather than with `PhaseFailure`
///
/// Because this half needs a catalogue, and `Presentation` must not have one.
/// The store decides *that* the content is unreadable and carries the field path
/// that proves it; this decides what that sentence reads like. Splitting the two
/// is what lets the store be tested without a language at all.
package extension PhaseFailure {
  var titleKey: TextKey {
    switch cause {
    case .unreachable, .nothingAvailable: InterfaceText.unavailableTitle
    case .malformed: InterfaceText.unreadableTitle
    }
  }

  /// The sentence, assembled from the catalogue.
  ///
  /// The malformed case carries its diagnosis in full rather than wrapped in an
  /// apology: this is a portfolio app, and somebody looking at it is better
  /// served by the actual field path than by "an error occurred".
  func message(_ text: LocalizedText) -> String {
    switch cause {
    case .unreachable:
      text(InterfaceText.unreachableMessage)
    case .nothingAvailable:
      text(InterfaceText.nothingAvailableMessage)
    case .malformed(let path, let reason):
      text(InterfaceText.malformed, path, Self.describe(reason, text))
    }
  }

  private static func describe(_ reason: MalformedReason, _ text: LocalizedText) -> String {
    switch reason {
    case .missingField:
      text(InterfaceText.malformedMissingField)
    case .unexpectedType(let expected):
      text(InterfaceText.malformedUnexpectedType, expected)
    case .nullValue(let expected):
      text(InterfaceText.malformedNullValue, expected)
    case .unreadable(let detail):
      detail
    case .wrongLanguage(let served, let requested):
      text(InterfaceText.malformedWrongLanguage, served, requested)
    case .unknownValue(let value):
      text(InterfaceText.malformedUnknownValue, value)
    case .unreadableDate(let raw):
      text(InterfaceText.malformedUnreadableDate, raw)
    case .monthOutOfRange(let raw):
      text(InterfaceText.malformedMonthOutOfRange, raw)
    case .unacceptableFileName(let name):
      text(InterfaceText.malformedUnacceptableFileName, name)
    case .insecureURL(let raw):
      text(InterfaceText.malformedInsecureURL, raw)
    }
  }
}
