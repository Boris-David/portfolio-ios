import Presentation
import SwiftUI

/// A tab's label: its word and its glyph.
///
/// ## Why the composition root does not build this itself
///
/// It tried, and the compiler refused — `titleKey` is `package`, and
/// `Composition` is another package. The refusal was right: resolving a key
/// needs the catalogue and the language on screen, which is view work, and the
/// composition root exists to **assemble**, not to draw.
///
/// So the root names a section and this turns it into a label. The tab bar is
/// then the only place in the app that says which four sections exist, which is
/// exactly where that belongs.
public struct SectionLabel: View {
  private let section: AppSection

  @Localized(.interface) private var text

  public init(_ section: AppSection) {
    self.section = section
  }

  public var body: some View {
    Label(text(section.titleKey), icon: section.icon)
  }
}
