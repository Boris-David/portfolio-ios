#!/usr/bin/env node
/**
 * `./Scripts/tokens.mjs`          writes the Swift derived from design/tokens.json
 * `./Scripts/tokens.mjs --check`  fails if it has diverged, or if the local copy
 *                                 of the tokens has drifted from the hub
 *
 * Design has **one** source: `design/tokens.json`, in the hub repository. The
 * site's CSS, the PDF résumé's template and this Swift file all descend from it
 * — no value is copied by hand anywhere.
 *
 * The `--check` mode is what turns "regenerate after touching the tokens" from a
 * discipline into a guard: CI runs it, and a divergence breaks the build instead
 * of being noticed by eye on a screen — that is, too late, and only on whichever
 * theme happened to be open.
 */
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, resolve, relative } from "node:path";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

/**
 * Two layers, assembled here.
 *
 * `tokens.json` is the copy from the hub: colours, spacing, radii, curves, type
 * scale. It is what the site and the PDF résumé share, and it is only ever
 * edited in the hub.
 *
 * `tokens.ios.json` carries only what makes sense on iOS alone — symbol sizes,
 * stroke widths, durations. The site would never see them, and lifting them into
 * the hub would clutter a shared source with values only one client uses.
 *
 * The assembly happens at generation time, not by hand: that is what allows an
 * iOS token to be added without touching the hub, and what lets the shared half
 * be checked for drift.
 */
const SHARED = resolve(ROOT, "design/tokens.json");
const PLATFORM = resolve(ROOT, "design/tokens.ios.json");
/** The hub, when working from inside the `portfolio` workspace. */
const UPSTREAM = resolve(ROOT, "../design/tokens.json");
const OUTPUT = resolve(ROOT, "Packages/DesignSystem/Sources/DesignSystem/Generated/Tokens.swift");

const check = process.argv.includes("--check");

const readOr = async (path, fallback) => {
  try {
    return await readFile(path, "utf8");
  } catch {
    return fallback;
  }
};

const source = await readFile(SHARED, "utf8");
const platformSource = await readFile(PLATFORM, "utf8");

/**
 * A group present on both sides would be a divergence in the making: the hub's
 * value and the client's would end up saying different things with nothing to
 * report it. Overlap is refused rather than resolved in favour of a winner.
 */
const shared = JSON.parse(source);
const platform = JSON.parse(platformSource);
const overlap = Object.keys(platform).filter(
  (key) => !key.startsWith("$") && Object.hasOwn(shared, key),
);
if (overlap.length > 0) {
  console.error(
    `✖ these groups exist on both sides: ${overlap.join(", ")}.\n` +
      "  A token is shared (hub) or specific (here), never both.",
  );
  process.exit(1);
}

const tokens = { ...shared, ...platform };

// ── Small conversions ──────────────────────────────────────────────────────

/** `#FAF8F3` → `(red: 0.98, green: 0.972, blue: 0.953)`, en composantes sRGB. */
function rgb(hex) {
  const value = hex.replace("#", "");
  const channel = (index) => parseInt(value.slice(index * 2, index * 2 + 2), 16) / 255;
  return [0, 1, 2].map((index) => channel(index).toFixed(4));
}

/** `cubic-bezier(.22,1,.36,1)` → `[0.22, 1, 0.36, 1]`. */
function bezier(css) {
  const numbers = css.match(/-?\d*\.?\d+/g);
  if (numbers?.length !== 4) {
    throw new Error(`Unreadable curve "${css}": four numbers expected.`);
  }
  return numbers.map((n) => (n.startsWith(".") ? `0${n}` : n));
}

/** `paper-2` → `paper2`, `on-accent` → `onAccent`: a Swift identifier. */
const camel = (name) => name.replace(/-(.)/g, (_, c) => c.toUpperCase());

const swiftName = (name) => (/^\d/.test(name) ? `s${name}` : camel(name));

// ── Generation ─────────────────────────────────────────────────────────────

const colorCases = Object.entries(tokens.color).map(([name, pair]) => {
  const [lr, lg, lb] = rgb(pair.light);
  const [dr, dg, db] = rgb(pair.dark);
  return `    /// \`${pair.light}\` in light, \`${pair.dark}\` in dark.
    public static let ${swiftName(name)} = Palette(
      light: Components(red: ${lr}, green: ${lg}, blue: ${lb}),
      dark: Components(red: ${dr}, green: ${dg}, blue: ${db})
    )`;
});

const spaceCases = Object.entries(tokens.space).map(
  ([step, value]) => `    /// \`${value}\` points.\n    public static let s${step}: CGFloat = ${value}`,
);

const radiusCases = Object.entries(tokens.radius).map(
  ([name, value]) => `    public static let ${swiftName(name)}: CGFloat = ${value}`,
);

const easeCases = Object.entries(tokens.ease).map(([name, css]) => {
  const [x1, y1, x2, y2] = bezier(css);
  return `    /// \`${css}\` — the same curve as on the website.
    public static let ${swiftName(name)} = Curve(x1: ${x1}, y1: ${y1}, x2: ${x2}, y2: ${y2})`;
});

const typeCases = Object.entries(tokens.type)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: CGFloat = ${value}`);

const iconCases = Object.entries(tokens.icon)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: CGFloat = ${value}`);

const strokeCases = Object.entries(tokens.stroke)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: CGFloat = ${value}`);

const opacityCases = Object.entries(tokens.opacity)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: Double = ${value}`);

const durationCases = Object.entries(tokens.duration)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: Double = ${value}`);

const elevationCases = Object.entries(tokens.elevation)
  .filter(([name]) => !name.startsWith("$"))
  .map(
    ([name, shadow]) =>
      `    public static let ${swiftName(name)} = Shadow(` +
      `radius: ${shadow.radius}, y: ${shadow.y}, opacity: ${shadow.opacity})`,
  );

const layoutCases = Object.entries(tokens.layout)
  .filter(([name]) => !name.startsWith("$"))
  .map(([name, value]) => `    public static let ${swiftName(name)}: CGFloat = ${value}`);

const generated = `// Generated by Scripts/tokens.mjs — DO NOT EDIT.
//
// ${tokens.$comment}
//
// Any hand edit will be overwritten, and \`./Scripts/tokens.mjs --check\` will
// refuse it in CI before it ever reaches a branch.
import CoreGraphics

public enum Tokens {}

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  /// A colour's sRGB components, with no interface framework involved.
  ///
  /// This file knows neither SwiftUI nor UIKit: \`DesignSystem/Colors.swift\`
  /// does the conversion. That keeps the generated file readable, testable, and
  /// independent of the platform it is compiled on.
  public struct Components: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
  }

  /// A colour and its dark-theme counterpart — both, always.
  ///
  /// The type makes impossible what otherwise happens every time: a colour
  /// defined for one theme only, unreadable on the other.
  public struct Palette: Sendable, Hashable {
    public let light: Components
    public let dark: Components
  }

  public enum Color {
${colorCases.join("\n")}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spacing — a 4-point scale, as on the website
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  public enum Space {
${spaceCases.join("\n")}
  }

  public enum Radius {
${radiusCases.join("\n")}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motion
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  /// A cubic Bézier curve, in the form CSS **and** \`Animation.timingCurve\`
  /// both expect. The two platforms therefore share the same feel of motion, to
  /// the value.
  public struct Curve: Sendable, Hashable {
    public let x1: Double
    public let y1: Double
    public let x2: Double
    public let y2: Double
  }

  public enum Ease {
${easeCases.join("\n")}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography
//
// ${tokens.type.$comment}
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  public enum TypeScale {
${typeCases.join("\n")}
  }

  public enum Accessibility {
    /// The smallest acceptable touch target, in points.
    public static let minimumTouchTarget: CGFloat = ${tokens.a11y.minTouchTarget}
    /// The contrast level aimed for.
    public static let contrastLevel = "${tokens.a11y.contrast}"
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS-specific — from design/tokens.ios.json
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  /// SF Symbol and illustration sizes, in points.
  public enum Icon {
${iconCases.join("\n")}
  }

  /// Stroke widths. \`hairline\` is half a point: one and a half pixels at 3×,
  /// the thinnest line that still renders crisply.
  public enum Stroke {
${strokeCases.join("\n")}
  }

  /// Named opacities — by what they mean, not by their value.
  public enum Opacity {
${opacityCases.join("\n")}
  }

  /// Animation durations, in seconds.
  ///
  /// The **curves** are shared with the website: the curve carries the feel, the
  /// duration tunes it to the medium. A touch screen has less patience than a
  /// web page.
  public enum Duration {
${durationCases.join("\n")}
  }

  /// A shadow described by the three numbers that only mean anything together.
  /// Splitting them invites changing one alone.
  public struct Shadow: Sendable, Hashable {
    public let radius: CGFloat
    public let y: CGFloat
    public let opacity: Double
  }

  public enum Elevation {
${elevationCases.join("\n")}
  }

  public enum Layout {
${layoutCases.join("\n")}
  }
}
`;

const shortPath = (path) => relative(ROOT, path);

if (!check) {
  await mkdir(dirname(OUTPUT), { recursive: true });
  await writeFile(OUTPUT, generated, "utf8");
  console.log(`✓ ${shortPath(OUTPUT)} écrit depuis design/tokens.json`);
  process.exit(0);
}

const failures = [];

const current = await readOr(OUTPUT, null);
if (current === null) {
  failures.push(`${shortPath(OUTPUT)} est absent — lancer ./Scripts/tokens.mjs`);
} else if (current !== generated) {
  failures.push(
    `${shortPath(OUTPUT)} diverge de design/tokens.json.\n` +
      "  Il a été modifié à la main, ou les tokens ont changé sans régénération.\n" +
      "  Corriger : ./Scripts/tokens.mjs",
  );
}

/**
 * La copie d'amont ne se vérifie que si l'amont est là. Sur un clone isolé de
 * `portfolio-ios` — donc en CI — il n'y a rien à comparer : on le dit, on ne
 * casse pas. Une garde qui échoue faute de contexte finit désactivée.
 */
const upstream = await readOr(UPSTREAM, null);
if (upstream === null) {
  console.log("· hub absent — la copie des tokens n'a pas été comparée.");
} else if (upstream !== source) {
  failures.push(
    "design/tokens.json a dérivé du hub.\n" +
      "  Le design a une seule source, et c'est celle du hub.\n" +
      "  Corriger : cp ../design/tokens.json design/tokens.json && ./Scripts/tokens.mjs",
  );
} else {
  console.log("✓ design/tokens.json est identique au hub.");
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`✖ ${failure}`);
  process.exit(1);
}
console.log("✓ les artefacts de design dérivent bien de design/tokens.json.");
