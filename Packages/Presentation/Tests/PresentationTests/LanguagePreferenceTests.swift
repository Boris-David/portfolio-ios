import Domain
import Testing
@testable import Presentation

/// The presentation layer is tested **without a renderer**, and that is the
/// point of it being a layer. No simulator, no view, no snapshot: values in,
/// values out.
struct ViewPhaseTests {
  @Test("a phase with nothing to show is pending")
  func pendingStates() {
    #expect(ViewPhase<Int>.initial.isPending)
    #expect(ViewPhase<Int>.loading.isPending)
    #expect(!ViewPhase.loaded(1).isPending)
    #expect(!ViewPhase<Int>.failed(.stub).isPending)
  }

  @Test("only a loaded phase carries a value")
  func valueOnlyWhenLoaded() {
    #expect(ViewPhase.loaded(42).value == 42)
    #expect(ViewPhase<Int>.initial.value == nil)
    #expect(ViewPhase<Int>.failed(.stub).value == nil)
  }
}

struct SectionTests {
  /// Each tab must be recognisable at a glance, which starts with not sharing
  /// an icon with its neighbour.
  @Test("every section has its own icon")
  func sectionsHaveDistinctIcons() {
    let icons = AppSection.allCases.map(\.icon)
    #expect(Set(icons).count == AppSection.allCases.count)
  }

  @Test("every section is titled in both languages", arguments: AppSection.allCases)
  func sectionsAreTitled(_ section: AppSection) {
    #expect(!section.title(.french).isEmpty)
    #expect(!section.title(.english).isEmpty)
    #expect(section.title(.french) != section.title(.english) || section.title(.english) == "Backstage")
  }
}

struct RouterTests {
  @MainActor
  @Test("popping an empty stack is a no-op, not a crash")
  func popOnEmpty() {
    let router = Router()
    router.pop()
    #expect(router.path.isEmpty)
  }

  @MainActor
  @Test("pushing then popping to root clears the stack")
  func pushAndPopToRoot() {
    let router = Router()
    router.push(.allApps)
    router.push(.caseStudy(slug: "kcalories"))
    #expect(router.path.count == 2)
    router.popToRoot()
    #expect(router.path.isEmpty)
  }
}

private extension PhaseFailure {
  static let stub = PhaseFailure(title: "t", message: "m", icon: .offline, isRetryable: true)
}
