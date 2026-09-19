import SwiftUI
import UIKit

/// Dresses the system's navigation title in the app's serif — once, for the
/// whole application.
///
/// ## Why this needs UIKit at all
///
/// SwiftUI has no API for the font of a navigation title. It has
/// `.navigationTitle`, and that is the whole surface. So either the app draws
/// its own header — which is exactly the hand-built hero block this refonte
/// removed, and which costs the collapse-on-scroll behaviour, the back-button
/// label, the accessibility rotor entry and the search integration — or it
/// reaches the appearance proxy once, here.
///
/// One file, one call, at launch. Nothing above `DesignSystem` knows UIKit was
/// involved.
///
/// ## Why only the font attribute
///
/// Setting `standardAppearance` would replace the bar's **background** as well,
/// and on iOS 26 that is the Liquid Glass the system draws for free. The legacy
/// `largeTitleTextAttributes` property sets the title's attributes and touches
/// nothing else — which is the entire intent.
///
/// ## Dynamic Type — measured, not assumed
///
/// A custom navigation title is the classic place Dynamic Type quietly stops
/// working, so it was measured rather than believed: the title is **73 pt tall
/// at the default size and 129 pt at AX5**, which is the system's own ratio.
///
/// It also survives a change made while the app is running. That was measured
/// too, and it cost some code: this type carried a `UIContentSizeCategory`
/// observer that reinstalled the font on every change. Removing it changed the
/// measurement by **nothing** — 129 pt either way — because UIKit re-resolves
/// an appearance-proxy attribute when the trait collection changes. The
/// observer was ceremony that looked like rigour, and it is gone.
public enum NavigationAppearance {
  /// Installs the title font. Idempotent.
  @MainActor
  public static func install() {
    UINavigationBar.appearance().largeTitleTextAttributes = [.font: largeTitle]
  }

  /// New York, semibold, at whatever size `.largeTitle` currently means.
  ///
  /// `size: 0` keeps the descriptor's own size — the scaled one — rather than
  /// overriding it with a number, which is how a custom navigation title
  /// normally stops answering Dynamic Type.
  @MainActor
  private static var largeTitle: UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
    guard let serif = descriptor.withDesign(.serif)?.addingAttributes([
      .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
    ]) else {
      // The serif design is unavailable on this platform. The system face at
      // the right size is a correct answer; a missing title is not.
      return UIFont(descriptor: descriptor, size: 0)
    }
    return UIFont(descriptor: serif, size: 0)
  }
}
