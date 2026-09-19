import Foundation

/// Where a link from the website lands in the application.
///
/// ## What the website actually publishes, and why that decides this type
///
/// One page per language — `/` and `/en` — with anchors for its sections:
/// `#cas`, `#parcours`, `#profondeur`, `#apps`, `#contact`. There is no
/// per-case-study URL, so there is nothing here that opens one. A mapping for
/// addresses the site will never produce would be a mapping nobody can test
/// against reality, and it is exactly how `/cas/*` came to be declared in the
/// association file for a path that does not exist.
///
/// ## Why a value, and why it lives in `Presentation`
///
/// Because *where a link leads* is a decision, not a rendering — the same
/// reason `Router` lives here. It is a pure function from a `URL` to a
/// destination, so every case is an assertion on a value with no simulator
/// involved: the anchors that map, the ones that do not, a foreign host, a
/// malformed address.
///
/// ## What it deliberately does not do
///
/// It does not change the language. `/en` says which page the reader came from,
/// not which language they want the app in — and the app's language is a
/// preference they may have set themselves. Someone reading the English site on
/// an English device already gets English, because the default resolves from
/// the device; someone who explicitly chose French chose it.
public struct DeepLink: Sendable, Hashable {
  /// The tab the link opens.
  public let section: AppSection
  /// A screen to present on arrival, when the link names one rather than a
  /// place to read.
  public let modal: Modal?

  public init(section: AppSection, modal: Modal? = nil) {
    self.section = section
    self.modal = modal
  }
}

public extension DeepLink {
  /// The hosts whose links this application answers.
  ///
  /// A single one today. It is checked rather than assumed: `onOpenURL` is
  /// handed whatever the system decides belongs to us, and an application that
  /// navigates on any URL it is given is an application that navigates on a URL
  /// somebody else chose.
  static let hosts: Set<String> = ["amissan.dev", "www.amissan.dev"]

  /// Reads a link, or answers `nil` when it leads nowhere this app can go.
  ///
  /// `nil` is not a failure to report: the reader tapped a link and the app
  /// opened, which is what they asked for. Landing them somewhere unrelated
  /// because a fragment was not recognised would be worse than landing them on
  /// the first screen.
  init?(_ url: URL) {
    guard let host = url.host()?.lowercased(), Self.hosts.contains(host) else { return nil }

    switch url.fragment()?.lowercased() {
    case "cas", "apps":
      // Both live in Work: the case studies, and the grid of production apps
      // under them.
      self.init(section: .work)
    case "parcours":
      self.init(section: .journey)
    case "contact":
      // The one anchor that names an action rather than a place to read.
      self.init(section: .profile, modal: .contact)
    case "profondeur", "contenu", nil:
      // `#profondeur` is the expertise block, which is on the profile — and so
      // is the top of the page, which is where a bare link lands.
      self.init(section: .profile)
    default:
      // An anchor this app has no screen for. The website gained a section and
      // the app has not, which is a thing that will happen: open the first
      // screen rather than guess.
      self.init(section: .profile)
    }
  }
}
