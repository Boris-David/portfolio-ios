/// The chosen appearance.
///
/// `system` is a **value in its own right**, not the absence of a choice: it
/// means "follow my phone", and it must survive a relaunch like the other two.
public enum AppearancePreference: String, Sendable, Hashable, CaseIterable {
  case system
  case light
  case dark
}
