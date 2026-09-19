import PDFKit
import SwiftUI

/// A PDF, displayed.
///
/// ## The name deliberately does not say "PDFKit"
///
/// Same rule as `MarkdownText` and `LottieAnimation`: this file is the only one
/// that names the framework. A screen asks for a preview of a document at a URL;
/// how it is drawn is this package's business.
///
/// ## Why a URL and not `Data`
///
/// `PDFView` reads a file without loading the whole document into memory, and a
/// résumé of several megabytes has no business passing through RAM. A file also
/// has a **name**, which is what the recipient of a share sees — anonymous
/// `Data` would travel under a name the system invented.
///
/// ## ⚠️ The order of two lines
///
/// `autoScales` measures the **current page**. Set before the document, it has
/// nothing to measure and the scale silently stays at 1 — the document renders,
/// at the wrong size, with no error anywhere. Found by looking at the screen,
/// which is the only way it could have been found.
public struct PDFPreview: UIViewRepresentable {
  private let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func makeUIView(context: Context) -> PDFView {
    let view = PDFView()
    view.displayMode = .singlePageContinuous
    view.displayDirection = .vertical
    view.backgroundColor = .clear
    view.document = PDFDocument(url: url)
    view.autoScales = true
    return view
  }

  public func updateUIView(_ view: PDFView, context: Context) {
    guard view.document?.documentURL != url else { return }
    view.document = PDFDocument(url: url)
    view.autoScales = true
  }
}
