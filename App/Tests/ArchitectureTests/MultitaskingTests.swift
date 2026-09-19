import Foundation
import Testing

/// Split View, held by the project file rather than by memory.
///
/// ## Why this is a test and not a note
///
/// Multitasking on iPad is **opt-out**, and the two ways out are a single line
/// each in a file nobody reads twice. An app that stops sharing the screen does
/// not crash, does not warn, and does not fail any other suite — it simply
/// refuses to sit beside Mail one day, and the reader who noticed was a
/// recruiter with an iPad.
@Suite("Multitasking")
struct MultitaskingTests {
  /// Read from the source tree, exactly as `DependencyGraphTests` reads the
  /// manifests: bundling a copy would create a second version that drifts, and
  /// SPM refuses a resource outside its own target anyway.
  private static let project: String = {
    var url = URL(fileURLWithPath: #filePath)
    // …/App/Tests/ArchitectureTests/MultitaskingTests.swift
    for _ in 0..<4 { url.deleteLastPathComponent() }
    url.appendPathComponent("project.yml")
    return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
  }()

  @Test("the project file is where this test says it is")
  func projectIsReadable() {
    #expect(!Self.project.isEmpty, "project.yml was not found — this suite would pass on nothing")
    #expect(Self.project.contains("PRODUCT_BUNDLE_IDENTIFIER"))
  }

  /// `UIRequiresFullScreen` is the switch that turns Split View off entirely.
  /// It is not set, and this is what keeps it that way.
  @Test("does not opt out of sharing the screen")
  func doesNotRequireFullScreen() {
    #expect(!Self.project.contains("UIRequiresFullScreen"))
  }

  /// iPadOS only offers Split View to an app that accepts **all four**
  /// orientations. Dropping one — which is tempting, because the phone is
  /// portrait-only here — silently removes multitasking with it.
  @Test("accepts every orientation on iPad", arguments: [
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
  ])
  func acceptsEveryOrientationOnPad(_ orientation: String) {
    guard let range = Self.project.range(of: "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad:") else {
      Issue.record("the iPad orientation key is missing entirely")
      return
    }
    let declared = Self.project[range.upperBound...].prefix(240)
    #expect(declared.contains(orientation), "\(orientation) is not offered on iPad")
  }

  /// The phone stays portrait: this app is read, and an editorial layout in
  /// landscape on a phone adds nothing anybody asked for. Stated here so that
  /// the two keys cannot quietly become the same one.
  @Test("keeps the phone portrait-only")
  func phoneStaysPortrait() {
    guard let range = Self.project.range(of: "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone:") else {
      Issue.record("the iPhone orientation key is missing entirely")
      return
    }
    let declared = Self.project[range.upperBound...].prefix(120)
    #expect(declared.contains("UIInterfaceOrientationPortrait"))
    #expect(!declared.contains("LandscapeLeft"))
  }
}
