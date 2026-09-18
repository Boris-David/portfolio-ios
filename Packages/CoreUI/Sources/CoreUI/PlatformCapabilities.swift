/// What the running OS can do — as a **fact**, never as a sentence.
///
/// Decisions uses it to tell the reader which of the two renderings they are
/// looking at. A compatibility trade-off you cannot observe on screen is a
/// trade-off you have to take on trust.
///
/// It used to return the wording itself, in French, from inside the design
/// system — which is a layer that cannot see the reader's language. The wording
/// moved to `AppChrome`; what stays here is the only thing this layer actually
/// knows.
public enum PlatformCapabilities {
  public static var supportsLiquidGlass: Bool {
    if #available(iOS 26.0, *) { true } else { false }
  }
}
