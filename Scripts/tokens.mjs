#!/usr/bin/env node
/**
 * `./Scripts/tokens.mjs`          écrit le Swift dérivé de design/tokens.json
 * `./Scripts/tokens.mjs --check`  échoue s'il diverge, ou si la copie des
 *                                 tokens a dérivé du hub
 *
 * Le design a **une** source : `design/tokens.json`, dans le dépôt hub. Le CSS
 * du site, le gabarit du CV en PDF et ce fichier Swift en descendent — aucune
 * valeur n'est recopiée à la main nulle part.
 *
 * Le mode `--check` est ce qui transforme « on régénère après avoir touché aux
 * tokens » d'une discipline en une garde : la CI l'exécute, et une divergence
 * casse la construction au lieu de se découvrir à l'œil sur un écran — c'est-à-
 * dire trop tard, et seulement sur le thème qu'on avait ouvert.
 */
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, resolve, relative } from "node:path";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

/**
 * Deux couches, assemblées ici.
 *
 * `tokens.json` est la copie du hub : couleurs, espacements, rayons, courbes,
 * échelle typographique. C'est ce que le site et le CV en PDF partagent, et il
 * ne se modifie que dans le hub.
 *
 * `tokens.ios.json` ne porte que ce qui n'a de sens que sur iOS — des tailles
 * de symboles, des épaisseurs de trait, des durées. Le site ne les verrait
 * jamais, et les hisser dans le hub encombrerait une source partagée avec des
 * valeurs qu'un seul client emploie.
 *
 * L'assemblage a lieu à la génération, pas à la main : c'est ce qui permet
 * d'ajouter un token iOS sans toucher au hub, et de vérifier que la part
 * partagée n'a pas dérivé.
 */
const SHARED = resolve(ROOT, "design/tokens.json");
const PLATFORM = resolve(ROOT, "design/tokens.ios.json");
/** Le hub, quand on travaille depuis le workspace `portfolio`. */
const UPSTREAM = resolve(ROOT, "../design/tokens.json");
const OUTPUT = resolve(ROOT, "Packages/AmissanDesignSystem/Sources/DesignSystem/Generated/Tokens.swift");

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
 * Un groupe présent des deux côtés serait une divergence en germe : la valeur
 * du hub et celle du client finiraient par ne plus dire la même chose, sans que
 * rien ne le signale. On refuse le recouvrement plutôt que de choisir un
 * gagnant.
 */
const shared = JSON.parse(source);
const platform = JSON.parse(platformSource);
const overlap = Object.keys(platform).filter(
  (key) => !key.startsWith("$") && Object.hasOwn(shared, key),
);
if (overlap.length > 0) {
  console.error(
    `✖ ces groupes existent des deux côtés : ${overlap.join(", ")}.\n` +
      "  Un token est partagé (hub) ou spécifique (ici), jamais les deux.",
  );
  process.exit(1);
}

const tokens = { ...shared, ...platform };

// ── Petites conversions ────────────────────────────────────────────────────

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
    throw new Error(`Courbe « ${css} » illisible : quatre nombres attendus.`);
  }
  return numbers.map((n) => (n.startsWith(".") ? `0${n}` : n));
}

/** `paper-2` → `paper2`, `on-accent` → `onAccent` : un nom d'identifiant Swift. */
const camel = (name) => name.replace(/-(.)/g, (_, c) => c.toUpperCase());

const swiftName = (name) => (/^\d/.test(name) ? `s${name}` : camel(name));

// ── Génération ─────────────────────────────────────────────────────────────

const colorCases = Object.entries(tokens.color).map(([name, pair]) => {
  const [lr, lg, lb] = rgb(pair.light);
  const [dr, dg, db] = rgb(pair.dark);
  return `    /// \`${pair.light}\` en clair, \`${pair.dark}\` en sombre.
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
  return `    /// \`${css}\` — la même courbe que sur le site.
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
// Toute modification à la main sera écrasée, et \`./Scripts/tokens.mjs --check\`
// la refusera en CI avant même qu'elle n'atteigne une branche.
import CoreGraphics

public enum Tokens {}

// ─────────────────────────────────────────────────────────────────────────────
// Couleurs
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  /// Les composantes sRGB d'une couleur, sans dépendre d'un framework d'interface.
  ///
  /// Le paquet ne connaît ici ni SwiftUI ni UIKit : \`DesignSystem/Colors.swift\`
  /// se charge de la conversion. Ça garde le fichier généré lisible, testable,
  /// et indépendant de la plateforme sur laquelle on le compile.
  public struct Components: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
  }

  /// Une couleur et son équivalent en thème sombre — les deux, toujours.
  ///
  /// Le type rend impossible ce qui arrive systématiquement autrement : une
  /// couleur définie pour un seul thème, qui devient illisible sur l'autre.
  public struct Palette: Sendable, Hashable {
    public let light: Components
    public let dark: Components
  }

  public enum Color {
${colorCases.join("\n")}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Espacements — une échelle de 4 points, comme sur le site
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
// Mouvement
// ─────────────────────────────────────────────────────────────────────────────

extension Tokens {
  /// Une courbe de Bézier cubique, dans la forme qu'attendent CSS **et**
  /// \`Animation.timingCurve\`. Les deux plateformes partagent donc la même
  /// sensation de mouvement, à la valeur près.
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
// Typographie
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
