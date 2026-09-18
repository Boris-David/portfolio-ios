import Presentation
import SwiftUI

extension Icon {
  /// The one place where a meaning becomes a glyph.
  ///
  /// Every symbol is picked for what it **designates**, not for its shape. And
  /// every one of them is checked by `IconTests`: an SF Symbol that does not
  /// exist renders nothing at all — no crash, no warning, just a hole where the
  /// icon was, on the one screen nobody opened before shipping.
  var systemName: String {
    switch self {
    case .offline: "wifi.slash"
    case .empty: "tray"
    case .malformed: "exclamationmark.triangle"
    case .profile: "person.crop.square"
    case .work: "square.stack.3d.up"
    case .journey: "calendar"
    case .backstage: "wrench.and.screwdriver"

    case .succeeded: "checkmark.circle.fill"
    case .failed: "exclamationmark.circle.fill"
    case .informed: "info.circle"

    case .settings: "gearshape"
    case .language: "globe"
    case .appearance: "circle.lefthalf.filled"
    case .resume: "doc.text"
    case .contact: "envelope"
    case .share: "square.and.arrow.up"
    case .close: "xmark"
    case .annotations: "number.circle"
    case .reset: "arrow.counterclockwise"
    case .link: "link"
    }
  }
}

package extension Image {
  /// Draws a presentation icon.
  init(_ icon: Icon) {
    self.init(systemName: icon.systemName)
  }
}

public extension Label where Title == Text, Icon == Image {
  /// A label whose glyph comes from a presentation meaning.
  init(_ title: String, icon: Presentation.Icon) {
    self.init(title, systemImage: icon.systemName)
  }
}
