import Decisions
import CoreUI
import DesignSystem
import Presentation
import SwiftUI
import TipKit
import ViewKit

/// The shell every tab is mounted in: a stack, its title, its destinations, the
/// zoom namespace, the annotation layer — and the native gesture of tapping the
/// tab you are already on.
///
/// Written once rather than copied into the four tabs. That is not only an
/// economy: `.navigationDestination(for:)` must be declared **once per stack and
/// per type**, and declaring it twice produces behaviour SwiftUI does not define
/// — it picks, without warning.
///
/// ## Why it takes a section and not a title
///
/// It took a string, and each screen resolved its own: `SectionShell(title:
/// text(InterfaceText.tab…))`. The tab bar resolved the same key again, in
/// `SectionLabel`. Two call sites for one word is one rename away from a tab
/// whose bar label and whose title disagree. The section *is* the identity —
/// the word, the glyph, and now the stack that answers to it.
package struct SectionShell<Content: View>: View {
  /// How a section's screen begins.
  ///
  /// Not a display mode passed through: the choice is editorial, and naming it
  /// after its mechanism ("inline") would leave the next reader guessing why
  /// one tab differs.
  package enum Opening {
    /// The system's large title opens the screen. For a section that is a
    /// **collection** — the title names what the list below it holds, then
    /// collapses into the bar as the reader scrolls.
    case sectionTitle
    /// The content opens itself. For a section whose first block is already a
    /// masthead.
    ///
    /// Measured, not assumed: with a large title, the profile tab read
    /// *"Profil"* in New York at 34 pt and then *"Amissan Amoussou-G."* in New
    /// York at 34 pt, forty points below it. Two titles in the same face and
    /// the same size, and the eye takes the second for a subtitle of the first
    /// — so the app's own name for its author looked like a caption.
    case content
  }

  private let section: AppSection
  private let opening: Opening
  private let content: Content

  @Environment(\.routeResolver) private var routes
  @Environment(\.present) private var present
  @Environment(\.initialRoute) private var initialRoute
  @Environment(SectionReselection.self) private var reselection
  @Localized(.interface) private var text

  @State private var router = Router()
  /// Bumped when the reader asks for the top of an already-rooted section.
  /// Read by `SectionScrollView`, which is the only thing that can scroll.
  @State private var scrollToTopRequests = 0
  /// The namespace both halves of a zoom transition match across.
  ///
  /// Declared **here** because this is the one view that contains both: the
  /// source is in the stack's root content, the destination is what the stack
  /// pushes. A namespace declared in a screen reached only the source, and a
  /// namespace declared in the scene reached only the destination — which is
  /// precisely how the app came to ship a zoom that matched nothing.
  @Namespace private var zoom

  package init(
    _ section: AppSection,
    opening: Opening = .sectionTitle,
    @ViewBuilder content: () -> Content
  ) {
    self.section = section
    self.opening = opening
    self.content = content()
  }

  package var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      content
        .background(Color.paper)
        .navigationTitle(text(section.titleKey))
        // ## Why `.large` here and `.inline` in depth
        //
        // The large title **is** the hero block, done by the system: it sets
        // the section's name in the app's serif, then collapses into the bar as
        // the reader scrolls. Every screen used to draw that block by hand —
        // surtitle, 34 pt title, standfirst — and pay a fixed slab of height
        // for it, on nine screens.
        //
        // What the system adds on top, and a hand-built header cannot: the
        // title is what the back button of the next screen is labelled with,
        // it is the first thing VoiceOver announces on arrival, and it is the
        // anchor a large-title collapse animates against.
        //
        // In depth it is `.inline`, which each pushed screen sets: down there
        // the title is a landmark, not an opening. And one root is `.inline`
        // too — see `Opening.content`.
        .navigationBarTitleDisplayMode(opening == .sectionTitle ? .large : .inline)
        .toolbar { toolbar }
        .navigationDestination(for: Route.self) { route in
          // The tab bar is **hidden** in depth, and the four roots keep it.
          //
          // ⚠️ This reverses an earlier decision recorded right here, so the
          // reasoning of both is worth keeping. The bar used to stay, on the
          // argument that a reader arrives from a link, reads one case study,
          // and wants the other three sections — a bar that vanishes turns
          // "look at the rest" into "find the back button first".
          //
          // The author overruled it after using the app, and his argument is
          // better: the reader is already inside one world, so offering to
          // change world right then is not great. A pushed screen is a reading
          // you came into deliberately and leave deliberately, and
          // offering four ways out of it while you are two paragraphs in is
          // offering to interrupt. It also makes the app consistent with
          // itself: a presented screen already hides the bar, and nobody found
          // that surprising.
          //
          // What it costs: on iOS 26 the résumé accessory rides on the tab bar,
          // so it goes too. One back tap away, and the toolbar still carries it
          // on iOS 18 where there is no accessory.
          routes(route)
        }
    }
    // ⚠️ The tab bar is a function of **depth**, declared once, on the stack.
    //
    // It was two declarations — hidden on the destination, visible on the root
    // — and they fought: the root's won, so nothing was ever hidden. Before
    // that it was one, on the destination only, and the bar could stay gone
    // after a pop because nobody ever said to bring it back.
    //
    // One expression, evaluated from the one thing that actually decides it,
    // cannot disagree with itself and has nothing to restore. At the root the
    // reader gets the four sections; in a reading they get the reading.
    .tabBar(router.path.isEmpty ? .visible : .hidden)
    .environment(router)
    .environment(\.openRoute, openRoute)
    .environment(\.zoomNamespace, zoom)
    .environment(\.scrollToTopRequests, scrollToTopRequests)
    // Tapping the active tab: the one navigation gesture every iOS app answers
    // and nothing in `TabView` reports. See `SectionReselection`.
    .onChange(of: reselection.count(section)) { _, _ in returnToStart() }
    // A route asked for at launch, pushed once the stack exists.
    //
    // It only serves reproducible screenshots of **pushed** screens, which no
    // other flag could reach. Applied here rather than in the root because the
    // stack that has to receive it is this one.
    .task {
      guard let initialRoute, router.path.isEmpty else { return }
      // Through the same action as a tap, so the flag cannot capture a screen
      // the reader would never be shown that way.
      openRoute(initialRoute)
    }
  }

  /// Push, until the stack is deep enough that pushing again would make a
  /// corridor — then present. See `OpenRouteAction`.
  private var openRoute: OpenRouteAction {
    OpenRouteAction { route in
      if router.path.count < Router.readableDepth {
        router.push(route)
      } else {
        present(.reading(route))
      }
    }
  }

  /// Back to the beginning of the section, the way iOS does it: the first tap
  /// unwinds the stack, and once there is nothing left to unwind the next tap
  /// takes the reader to the top of the page.
  ///
  /// Doing both at once was the first version, and it was wrong: popping out of
  /// a case study also threw away the reader's place in the list they had
  /// scrolled to.
  private func returnToStart() {
    if router.path.isEmpty {
      scrollToTopRequests += 1
    } else {
      router.popToRoot()
    }
  }

  /// Settings on every tab root rather than on one screen: they belong to the
  /// app, and a reader who wants them should not have to remember which section
  /// hides them.
  ///
  /// The résumé used to sit beside it, permanently — *"getting to the CV
  /// download has to be easier and more obvious."* On iOS 26 it has somewhere
  /// better: `tabViewBottomAccessory`, a control docked under the tab bar that
  /// follows the reader everywhere and is far more visible than a 24 pt glyph.
  /// It stays in the toolbar on iOS 18, which has no such slot — so the command
  /// exists exactly once on each OS, never twice.
  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    if !PlatformCapabilities.supportsLiquidGlass {
      ToolbarItem(placement: .topBarTrailing) {
        Button { present(.resume) } label: {
          Label(text(InterfaceText.resumeAction), icon: .resume)
        }
        .accessibilityLabel(text(InterfaceText.resumeAction))
      }
    }
    ToolbarItem(placement: .topBarTrailing) {
      Button { present(.settings) } label: {
        Label(text(InterfaceText.settings), icon: .settings)
      }
      .accessibilityLabel(text(InterfaceText.settings))
      // The one tip in the app, anchored to where the switch lives.
      .popoverTip(DecisionsTip(title: text(InterfaceText.tipTitle), message: text(InterfaceText.tipMessage)))
    }
  }
}
