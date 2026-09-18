import DesignSystem
import SwiftUI

/// An image that belongs to the **content**, resolved from its slug.
///
/// ## Why these assets left the app target
///
/// They were in `App/Resources/Assets.xcassets`, next to the app icon, and they
/// worked — `Image("tcl")` resolves against `Bundle.main`, which is the app.
/// Working is not the same as being in the right place.
///
/// The app target should hold what makes it an **app**: a `@main`, an
/// `Info.plist`, an entitlements file, an icon. Thirty-nine transport operator
/// logos and product screenshots are not that. They are content — they pair with
/// what the API serves, by slug — and they belong with the layer that draws
/// them.
///
/// `AppIcon` stayed behind, and that is not an inconsistency:
/// `ASSETCATALOG_COMPILER_APPICON_NAME` resolves against the application's own
/// catalogue. It is identity, not content.
///
/// ## Why the bundle is named here and nowhere else
///
/// `Bundle.module` is **internal to each target**. A screen writing
/// `Image("tcl", bundle: .module)` would name its own bundle, find nothing, and
/// render an empty frame — silently, because a missing image is not an error in
/// SwiftUI. Resolving it in one place makes that impossible.
///
/// ## The day these come from the API
///
/// One type changes. Call sites ask for a slug; they never learn that a `.png`
/// exists, which is the same rule the domain follows with `Media`.
package struct ContentImage: View {
  /// What kind of content this is — and therefore which shape it takes.
  package enum Kind {
    /// A production app's icon: square, rounded like a home-screen icon.
    case appIcon
    /// A product screenshot: a phone-shaped still.
    case screenshot
  }

  private let slug: String
  private let kind: Kind
  private let label: String?

  package init(_ slug: String, kind: Kind, label: String? = nil) {
    self.slug = slug
    self.kind = kind
    self.label = label
  }

  package var body: some View {
    image
      .resizable()
      .aspectRatio(contentMode: kind == .appIcon ? .fill : .fit)
      .accessibilityLabel(label ?? "")
      // A decorative image announced as "image" is noise; one with a label is
      // information. The caller decides which it is by passing a label or not.
      .accessibilityHidden(label == nil)
  }

  private var image: Image {
    Image(slug, bundle: .contentAssets)
  }
}

extension Bundle {
  /// The bundle that carries the content catalogue.
  ///
  /// Not `public`: no layer above needs to know a bundle is involved. They ask
  /// `ContentImage` for a slug.
  static let contentAssets = Bundle.module
}
