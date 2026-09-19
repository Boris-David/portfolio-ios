import Decisions
import Foundation
import Localization

/// The design decisions annotated on the Resume screens.
///
/// ## What a declaration says, and what it does not
///
/// It says **which** decision, on **which** component, and where Apple documents
/// it. Every sentence a reader sees lives in `Resources/Localizable.xcstrings`,
/// beside this file, keyed off the identifier: `<id>.role`, `<id>.rationale`,
/// `<id>.whenToUse`, `<id>.pitfall`, and `<id>.rejected.1.name` / `.because`.
///
/// So changing a piece of text never reopens a Swift file, let alone a `body`.
/// Adding a language adds a column to the catalogue and not one line of code.
enum ResumeDecisions {
  static let pdf = DesignDecision(
    id: "resume.pdf",
    component: "PDFKit · PDFView",
    documentation: URL(string: "https://developer.apple.com/documentation/pdfkit/pdfview"),
    in: .resume
  )
  static let share = DesignDecision(
    id: "resume.share",
    component: "ShareLink",
    documentation: URL(string: "https://developer.apple.com/documentation/swiftui/sharelink"),
    in: .resume
  )
}

extension TextCatalogue {
  /// This feature's catalogue, read from this module's own bundle.
  ///
  /// One per screen module rather than one shared file: the text sits beside the
  /// code it belongs to, and a feature cannot silently depend on a sentence
  /// another feature owns.
  static let resume = TextCatalogue(bundle: .module, table: "Localizable")
}
