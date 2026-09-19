import DesignSystem

/// Which animation to play — never which file draws it.
///
/// ## Why this enum exists
///
/// It is the same argument as `Icon`, one layer down. A call site that writes
/// `LottieAnimation("downloaded")` is spelling a file name, and a misspelt file
/// name is the worst kind of defect this codebase has: Lottie answers a missing
/// resource with an **empty frame**, silently. Nothing crashes, nothing warns,
/// and the screen simply has a hole in it that only a screenshot reveals.
///
/// An enum case cannot be misspelt. And once the set is closed, three more
/// things follow:
///
/// - the mapping to file names lives in one `switch`, so renaming a file is one
///   edit rather than a search across the feature packages;
/// - whether an animation loops stops being a decision taken at the call site.
///   It is a property of the animation — a state persists, an event does not —
///   and a caller that *could* get it wrong eventually does;
/// - the token colours each file is drawn from are written down next to the
///   case, which is what lets `LottieCatalogueTests` check the JSON against the
///   design tokens instead of trusting a comment.
///
/// ## The colour mapping — hex in, Lottie out
///
/// Lottie stores a colour as `[r, g, b, a]` with each channel normalised to
/// 0–1. There are no comments in JSON, so the correspondence is recorded here,
/// and `palette` below makes it executable rather than decorative.
///
/// | Token | Hex (light) | In the JSON | Used by |
/// |---|---|---|---|
/// | `Tokens.Color.accent.light` | `#2743D6` | `[0.1529, 0.2627, 0.8392, 1]` | `signature`, `unreachable` |
/// | `Tokens.Color.ink3.light` | `#5B5546` | `[0.3569, 0.3333, 0.2745, 1]` | `empty`, `unreachable` |
/// | `Tokens.Color.line2.light` | `#C9C1B1` | `[0.7882, 0.7569, 0.6941, 1]` | `empty` |
/// | `Tokens.Color.ok.light` | `#1E7F4F` | `[0.1176, 0.4980, 0.3098, 1]` | `downloaded` |
///
/// ⚠️ **The light half of each palette is baked in.** A Lottie file carries its
/// own colours, and this wrapper installs no value provider, so the dark theme
/// gets the light values. That is why every animation is drawn in mid-tones —
/// `ink3`, `line2`, `accent`, `ok` all clear the paper in both themes — rather
/// than in `ink` or `paper`, which would vanish into one of them. The honest
/// fix is a colour provider driven by the colour scheme; it is not in this
/// change, and until it is, the palette choice is the thing holding the line.
///
/// ## The durations are tokens too
///
/// Every timing in the three files is a value from the `duration` group of
/// `design/tokens.ios.json`, at 60 frames per second — the frame rate
/// the catalogue is authored at:
///
/// | Token | Seconds | Frames | Where |
/// |---|---|---|---|
/// | `Tokens.Duration.counter` | 1.1 | 66 | one half of the `empty` float, one half of the `unreachable` cycle |
/// | `Tokens.Duration.pop` | 0.5 | 30 | the `downloaded` ring, the `unreachable` recoil |
/// | `Tokens.Duration.entrance` | 0.45 | 27 | the `downloaded` check, the `unreachable` return |
///
/// So `downloaded` runs 30 + 27 = 57 frames, or 0.95 s, and the two looping
/// files run 2 × 66 = 132 frames, or 2.2 s. The curves are the `ease` tokens,
/// written as Lottie keyframe tangents.
public enum LottieCatalogue: Sendable, Hashable, CaseIterable {
  /// The stroke drawn under the author's name, on the welcome screen.
  ///
  /// ⚠️ It was deleted once, correctly: the identity block it lived under had
  /// gone, so nothing called it and the repository forbids dead code. It came
  /// back with a caller — which is the only reason an asset comes back.
  case signature
  /// Nothing to show here — a dashed page, floating over its own shadow.
  case empty
  /// The content could not be reached — a severed link, cut by a slash.
  case unreachable
  /// The résumé finished downloading — a ring, then a check.
  case downloaded
}

extension LottieCatalogue {
  /// The resource's base name in `Bundle.coreUI`.
  ///
  /// Deliberately not a raw value: a raw-value enum ties the file name to the
  /// case name, so renaming one renames the other by accident. Here the two can
  /// be renamed independently, and the mapping is something a reader can see.
  var fileName: String {
    switch self {
    case .empty: "empty"
    case .unreachable: "unreachable"
    case .signature: "signature"
    case .downloaded: "downloaded"
    }
  }

  /// Whether the animation runs until the view goes away.
  ///
  /// The rule is what the animation *is*, not where it is shown: a **state**
  /// loops, an **event** plays once and settles on its final frame. Both empty
  /// and unreachable are states the screen stays in; a signature being drawn and
  /// a finished download are things that happened.
  var repeats: Bool {
    switch self {
    case .signature, .downloaded: false
    case .empty, .unreachable: true
    }
  }

  /// Where each token colour is used inside the file.
  ///
  /// ## Why a keypath and not just a list of colours
  ///
  /// A Lottie file bakes its colours in. The list alone was enough to *check*
  /// them — and not enough to *change* them, which is what the dark theme needs:
  /// both themes were getting the light values, and `accent` on dark paper came
  /// out at about 2.3:1. Legible, and the dimmest thing on the screen.
  ///
  /// Pairing each colour with the layer it belongs to makes the swap possible:
  /// `LottieAnimation` installs a value provider per keypath when the scheme is
  /// dark. The `**` matches any depth of group below the layer, so the file can
  /// be restructured inside a layer without this list moving.
  ///
  /// It also keeps the check: `LottieCatalogueTests` reads every colour out of
  /// the JSON and asserts it appears here, so a hand edit that drifts off the
  /// palette fails the suite instead of quietly shipping an off-brand animation.
  var tints: [(keypath: String, palette: Tokens.Palette)] {
    switch self {
    case .signature:
      [("stroke.**.Color", Tokens.Color.accent)]
    case .empty:
      [("sheet.**.Color", Tokens.Color.ink3), ("ground.**.Color", Tokens.Color.line2)]
    case .unreachable:
      [
        ("break.**.Color", Tokens.Color.accent),
        ("left end.**.Color", Tokens.Color.ink3),
        ("right end.**.Color", Tokens.Color.ink3),
      ]
    case .downloaded:
      [("mark.**.Color", Tokens.Color.ok), ("ring.**.Color", Tokens.Color.ok)]
    }
  }

  /// The light values the JSON is authored with, derived from `tints`.
  ///
  /// Derived rather than listed a second time: two lists that must agree are two
  /// lists that will not.
  var palette: [[Double]] {
    var seen: [[Double]] = []
    for tint in tints {
      let channels = Self.channels(tint.palette.light)
      if !seen.contains(channels) { seen.append(channels) }
    }
    return seen
  }

  /// The frame count the file declares as its out point.
  ///
  /// Written as the sum of the duration tokens it is made of, at 60 frames per
  /// second, rather than as the number itself. The arithmetic is the point: if
  /// somebody retunes `Tokens.Duration.pop`, this stops matching the JSON and
  /// the suite says so — which is the only way a generated token and a
  /// hand-written file stay in step.
  var frameCount: Double {
    switch self {
    case .signature:
      // Predates the duration tokens: 72 frames, written before that rule.
      72
    case .empty, .unreachable:
      2 * Self.frames(Tokens.Duration.counter)
    case .downloaded:
      Self.frames(Tokens.Duration.pop) + Self.frames(Tokens.Duration.entrance)
    }
  }

  /// The frame rate every file in the catalogue is authored at. One rate for
  /// the bundle: two is a discrepancy nobody remembers on the day they edit the
  /// second file.
  static let frameRate: Double = 60

  private static func frames(_ seconds: Double) -> Double {
    (seconds * frameRate).rounded()
  }

  private static func channels(_ color: Tokens.Components) -> [Double] {
    [color.red, color.green, color.blue]
  }
}
