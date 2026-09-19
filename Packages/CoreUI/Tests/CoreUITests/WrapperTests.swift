import SwiftUI
import Testing
@testable import CoreUI

/// The wrappers exist so that one file names a library. This suite guards the
/// half of that promise a manifest cannot: that the wrapper is **usable without
/// knowing what is behind it**.
@MainActor
struct WrapperTests {
  /// A component that has to be decorated at every call site is a component
  /// somebody reimplements next door. Font and colour are parameters with
  /// defaults, so the common case is one argument.
  @Test("the markdown wrappers are usable with a single argument")
  func markdownDefaults() {
    _ = MarkdownText("**bold** and `code`")
    _ = InlineMarkdown("a sentence with *emphasis*")
  }

  @Test("the markdown wrappers take a font and a colour")
  func markdownIsConfigurable() {
    _ = MarkdownText("x", font: .caption, color: .red)
    _ = InlineMarkdown("x", font: .caption, color: .red)
  }

  @Test("the animation wrapper reads this package's bundle by default")
  func animationUsesOwnBundle() {
    // The animations are resources of `CoreUI`. `Bundle.module` is internal to
    // each target, so a screen asking for one would get its own bundle and find
    // nothing — silently. `.coreUI` names the right one.
    //
    // Asserted over the whole catalogue rather than on one file: naming a
    // single animation is how this check survived that animation being deleted
    // in a form that still compiled and still said nothing.
    for animation in LottieCatalogue.allCases {
      #expect(Bundle.coreUI.url(forResource: animation.fileName, withExtension: "json") != nil)
    }
  }
}

struct PlatformCapabilitiesTests {
  /// The app ships one binary for two rendering worlds. This is the switch, and
  /// it is a fact rather than a sentence — the wording lives in `AppChrome`,
  /// where the reader's language is known.
  @Test("the platform reports one rendering world or the other")
  func reportsARendering() {
    let supports = PlatformCapabilities.supportsLiquidGlass
    if #available(iOS 26.0, *) {
      #expect(supports)
    } else {
      #expect(!supports)
    }
  }
}
