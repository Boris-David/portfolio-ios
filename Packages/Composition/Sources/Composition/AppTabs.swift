import CoreUI
import DesignSystem
import FeatureEngineering
import FeatureJourney
import FeatureProfile
import FeatureWork
import Presentation
import SwiftUI
import ViewKit

/// The four tabs, and the one place that knows which screen each one holds.
///
/// ## Why four and not five
///
/// Three to five is the range a phone tab bar reads well in. Below three, a tab
/// bar is a segmented control wearing the wrong clothes; above five, the labels
/// truncate and the icons stop being distinguishable at a glance.
///
/// Each tab is a **destination**, never an action: nothing here creates,
/// shares or scans. A tab that performs an action breaks the one promise a tab
/// bar makes — that tapping it shows you where you were.
struct AppTabs: View {
  @Binding var selection: AppSection

  var body: some View {
    TabView(selection: $selection) {
      Tab(value: AppSection.profile) {
        ProfileScreen()
      } label: {
        SectionLabel(.profile)
      }

      Tab(value: AppSection.work) {
        WorkScreen()
      } label: {
        SectionLabel(.work)
      }

      Tab(value: AppSection.journey) {
        JourneyScreen()
      } label: {
        SectionLabel(.journey)
      }

      Tab(value: AppSection.decision) {
        EngineeringScreen()
      } label: {
        SectionLabel(.decision)
      }
    }
    // The bar shrinks as you read down: the content is what you came for, the
    // navigation can step aside. iOS 26 only; on iOS 18 the bar stays, which is
    // its normal behaviour and not a defect.
    .minimizingTabBarOnScroll()
  }
}
