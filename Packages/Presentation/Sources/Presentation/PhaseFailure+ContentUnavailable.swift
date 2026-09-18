import Domain

public extension PhaseFailure {
  /// Turns a domain failure into something a screen can render.
  ///
  /// ## Why this mapping lives in exactly one place
  ///
  /// It did not, and the cost was visible: `PortfolioStore` translated
  /// `.nothingAvailable` to an empty-tray icon while a second copy of the same
  /// `switch`, written inside a view, translated it to a crossed-out wifi
  /// symbol. The same failure looked like two different failures depending on
  /// which screen you were standing on — and neither was wrong on its own,
  /// which is why nobody noticed.
  ///
  /// Duplicated presentation logic does not announce itself by breaking. It
  /// announces itself by drifting.
  init(_ failure: ContentUnavailable, chrome: AppChrome) {
    switch failure {
    case .unreachable:
      self.init(
        title: chrome.unavailableTitle,
        message: chrome.unreachableMessage,
        icon: .offline,
        isRetryable: true
      )

    case .nothingAvailable:
      self.init(
        title: chrome.unavailableTitle,
        message: chrome.nothingAvailableMessage,
        icon: .empty,
        isRetryable: true
      )

    case .malformed(let path, let reason):
      // Retrying would change nothing: the source would answer the same thing.
      // So there is no button — and the message carries the real diagnosis.
      // This is a portfolio app; someone looking at it is better served by the
      // actual path than by a padded apology.
      self.init(
        title: chrome.unreadableTitle,
        message: chrome.malformedMessage(path: path, reason: reason),
        icon: .malformed,
        isRetryable: false
      )
    }
  }
}
