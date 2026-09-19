import Foundation
import Testing
@testable import Presentation

/// Where a link from the website lands.
///
/// Every case here is a real address the site can produce — one page per
/// language, with anchors — and the two that matter most are the ones that
/// produce **nothing**: a host that is not ours, and a fragment we have no
/// screen for.
struct DeepLinkTests {
  @Test("the bare address opens the first screen", arguments: [
    "https://amissan.dev/",
    "https://amissan.dev/en",
    "https://www.amissan.dev/",
  ])
  func bareAddress(_ address: String) {
    #expect(DeepLink(URL(string: address)!)?.section == .profile)
  }

  @Test("each anchor the site publishes opens its tab")
  func anchors() {
    #expect(DeepLink(URL(string: "https://amissan.dev/#cas")!)?.section == .work)
    #expect(DeepLink(URL(string: "https://amissan.dev/#apps")!)?.section == .work)
    #expect(DeepLink(URL(string: "https://amissan.dev/en#parcours")!)?.section == .journey)
    #expect(DeepLink(URL(string: "https://amissan.dev/#profondeur")!)?.section == .profile)
  }

  /// The one anchor that names an action. A reader who taps "contact" on the
  /// site wants the address, not the screen the address is on.
  @Test("the contact anchor presents the contact screen")
  func contactPresents() {
    let link = DeepLink(URL(string: "https://amissan.dev/#contact")!)
    #expect(link?.section == .profile)
    #expect(link?.modal == .contact)
  }

  /// An application that navigates on any URL it is handed is an application
  /// that navigates on a URL somebody else chose.
  @Test("a link from another host leads nowhere", arguments: [
    "https://amissan.dev.evil.example/#cas",
    "https://example.com/#cas",
    "https://api.amissan.dev/v1/portfolio",
  ])
  func foreignHost(_ address: String) {
    #expect(DeepLink(URL(string: address)!) == nil)
  }

  /// The site will gain a section before the app does. That is not an error to
  /// report — the reader tapped a link and the app opened, which is what they
  /// asked for.
  @Test("an anchor with no screen opens the first one rather than guessing")
  func unknownAnchor() {
    #expect(DeepLink(URL(string: "https://amissan.dev/#une-section-a-venir")!)?.section == .profile)
    #expect(DeepLink(URL(string: "https://amissan.dev/#une-section-a-venir")!)?.modal == nil)
  }

  @Test("the anchor is read whatever its case")
  func caseInsensitive() {
    #expect(DeepLink(URL(string: "https://AMISSAN.dev/#CAS")!)?.section == .work)
  }
}
