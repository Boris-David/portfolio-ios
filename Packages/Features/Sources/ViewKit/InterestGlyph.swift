import Foundation

/// The glyph that goes beside an interest.
///
/// ## Why the mapping lives here and not in the content
///
/// The API publishes an **identity** — `strength`, `nutrition` — and never a
/// symbol name. `dumbbell.fill` means nothing to the website and nothing at all
/// to the résumé; it is an iOS detail, and iOS is where it belongs.
///
/// An unknown identity gets no glyph rather than a wrong one. A missing symbol
/// name renders as a blank square in SwiftUI, which looks like a defect; a chip
/// with only its label looks like a chip.
package enum InterestGlyph {
  package static func name(for id: String) -> String? {
    switch id {
    case "strength": "dumbbell.fill"
    case "nutrition": "fork.knife"
    case "football": "soccerball"
    case "photography": "camera.fill"
    case "travel": "airplane"
    default: nil
    }
  }
}
