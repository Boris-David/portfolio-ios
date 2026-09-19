#!/usr/bin/env bash
#
# The string catalogues: complete, reachable, and the only place text lives.
#
# ## What this replaces
#
# Text used to be a Swift value carrying both languages side by side, so a
# missing translation did not compile. Moving to `.xcstrings` bought three things
# — plurals that follow the language, text a non-developer can edit, and a third
# language for the price of a column — and cost exactly one: a missing
# translation is now **silent**. The key renders on screen, looking almost like a
# label.
#
# This is the repayment. It runs in CI, which is a worse place to learn than the
# compiler, and a far better one than a screenshot.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

# ── Every catalogue: valid, complete, and agreeing on which languages exist ──
#
# ⚠️ The language set must be the **same everywhere**. One catalogue missing a
# language does not fail: it falls back, so one screen quietly speaks the other
# language while its neighbours do not.
python3 - <<'PY' || status=1
import json, pathlib, sys

status = 0
# ⚠️ `.build/` holds *compiled copies* of these same catalogues. Reading them
# made this guard answer about an artefact that a `swift build` may have left
# behind weeks ago — it fired on a stale bundle during its own mutation test.
catalogues = sorted(p for p in pathlib.Path("Packages").rglob("*.xcstrings")
                    if ".build" not in p.parts and "DerivedData" not in p.parts)
if not catalogues:
    print("✖ no string catalogue found at all", file=sys.stderr)
    sys.exit(1)

languages = {}
for path in catalogues:
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        print(f"✖ {path}: not valid JSON — {error}", file=sys.stderr)
        status = 1
        continue

    found = set()
    for key, entry in sorted(data.get("strings", {}).items()):
        localizations = entry.get("localizations", {})
        if not localizations:
            print(f"✖ {path}: '{key}' carries no translation at all", file=sys.stderr)
            status = 1
            continue
        found |= set(localizations)
        for language, localization in sorted(localizations.items()):
            units = []
            if "stringUnit" in localization:
                units.append(("", localization["stringUnit"]))
            for form, variation in localization.get("variations", {}).get("plural", {}).items():
                units.append((f" ({form})", variation["stringUnit"]))
            if not units:
                print(f"✖ {path}: '{key}' [{language}] has neither a value nor plural forms",
                      file=sys.stderr)
                status = 1
            for suffix, unit in units:
                if not unit.get("value", "").strip():
                    print(f"✖ {path}: '{key}' [{language}]{suffix} is empty", file=sys.stderr)
                    status = 1
                if unit.get("state") != "translated":
                    print(f"✖ {path}: '{key}' [{language}]{suffix} is '{unit.get('state')}', "
                          "not 'translated'", file=sys.stderr)
                    status = 1
    if found:
        languages[path] = found

distinct = {frozenset(found) for found in languages.values()}
if len(distinct) > 1:
    print("✖ the catalogues do not agree on which languages exist:", file=sys.stderr)
    for path, found in sorted(languages.items()):
        print(f"    {path}: {', '.join(sorted(found))}", file=sys.stderr)
    status = 1

sys.exit(status)
PY

# ── Every decision reads keys that exist, and no key is unreachable ──────────
python3 - <<'PY' || status=1
import json, pathlib, re, sys

status = 0
REQUIRED = ("role", "rationale", "whenToUse")
OPTIONAL = ("pitfall",)

for declaration in sorted(pathlib.Path("Packages/Features/Sources/Features").glob("*/[A-Z]*Decisions.swift")):
    folder = declaration.parent
    catalogue_path = folder / "Resources" / "Localizable.xcstrings"
    if not catalogue_path.exists():
        print(f"✖ {declaration}: declares decisions but {catalogue_path} is missing", file=sys.stderr)
        status = 1
        continue

    keys = set(json.loads(catalogue_path.read_text()).get("strings", {}))
    identifiers = re.findall(r'id: "([^"]+)"', declaration.read_text())
    if not identifiers:
        print(f"✖ {declaration}: no decision declared, yet a catalogue sits beside it", file=sys.stderr)
        status = 1

    reachable = set()
    for identifier in identifiers:
        for field in REQUIRED:
            key = f"{identifier}.{field}"
            if key not in keys:
                print(f"✖ {catalogue_path}: '{key}' is missing — a decision without a "
                      f"{field} is not yet a decision", file=sys.stderr)
                status = 1
            reachable.add(key)
        for field in OPTIONAL:
            reachable.add(f"{identifier}.{field}")
        # Ruled-out candidates are read by walking from 1 until one is absent, so
        # a gap leaves everything after it unread — silently.
        index = 1
        while f"{identifier}.rejected.{index}.name" in keys:
            for part in ("name", "because"):
                key = f"{identifier}.rejected.{index}.{part}"
                if key not in keys:
                    print(f"✖ {catalogue_path}: '{key}' is missing", file=sys.stderr)
                    status = 1
                reachable.add(key)
            index += 1

    for key in sorted(keys - reachable):
        print(f"✖ {catalogue_path}: '{key}' is unreachable — nothing reads it, and a gap in "
              "the numbering hides every candidate after it", file=sys.stderr)
        status = 1

sys.exit(status)
PY

# ── Every typed key names an entry that exists ───────────────────────────────
python3 - <<'PY' || status=1
import json, pathlib, re, sys

status = 0
# Each namespace, and the catalogue it reads from.
NAMESPACES = {
    "Packages/Features/Sources/ViewKit/Localization/InterfaceText.swift":
        "Packages/Features/Sources/ViewKit/Resources/Localizable.xcstrings",
    "Packages/Features/Sources/Decisions/DecisionLabels.swift":
        "Packages/Features/Sources/Decisions/Resources/Localizable.xcstrings",
}

for source, catalogue_path in NAMESPACES.items():
    keys = set(json.loads(pathlib.Path(catalogue_path).read_text()).get("strings", {}))
    declared = set(re.findall(r'TextKey = "([^"]+)"', pathlib.Path(source).read_text()))

    for key in sorted(declared - keys):
        print(f"✖ {source}: '{key}' has no entry in {catalogue_path} — it would render as "
              "itself, on screen", file=sys.stderr)
        status = 1
    for key in sorted(keys - declared):
        print(f"✖ {catalogue_path}: '{key}' is never named by {source}", file=sys.stderr)
        status = 1

sys.exit(status)
PY

# ── A screen never writes a sentence ─────────────────────────────────────────
#
# The rule the whole migration exists for: a view names a key, the catalogue
# holds the word. A literal here is not a style slip — it is a sentence that no
# translator will ever find.
for file in $(find Packages/Features/Sources -name "*.swift" \
                ! -name "InterfaceText.swift" ! -name "DecisionLabels.swift" \
                ! -path "*/Localization/*" 2>/dev/null); do
  if grep -nE '(Text|Label|Button)\("[^"\\%]{4,}"' "$file" | grep -qv '//' ; then
    grep -nE '(Text|Label|Button)\("[^"\\%]{4,}"' "$file" \
      | sed "s|^|✖ $file:|" >&2
    status=1
  fi
done


# -- Nobody outside the two resolvers ever names a language -------------------
#
# The language on screen is set **once**, by the scene, and read by exactly two
# property wrappers: `Localized`, for catalogue keys, and `LocalizedDecision`,
# for a decision's own sentences.
#
# Any other reader is a type that *could* branch on a language, and every one
# that existed did eventually pass it somewhere else: `DecisionSheet` threaded it
# through five calls, `ResumeScreen` handed it to a store that should have held
# its own, `SectionShell` passed it to a tip. None of them was wrong; all of them
# were a language being managed outside the one place that manages languages.
ALLOWED="Localization/Localized.swift Decisions/DecisionText.swift ViewKit/ContentLanguage.swift Composition/SceneEnvironment.swift"
while read -r found; do
  [ -z "$found" ] && continue
  file="${found%%:*}"
  keep=false
  for allowed in $ALLOWED; do
    case "$file" in *"$allowed") keep=true ;; esac
  done
  $keep && continue
  echo "X $found" >&2
  echo "  the language is read by the resolvers, and by nothing else" >&2
  status=1
done <<< "$(grep -rn 'Environment(\\.contentLanguage)' Packages/*/Sources --include="*.swift" 2>/dev/null || true)"

# And no type at all enumerates the languages that exist: that list is whatever
# the compiled catalogue contains. A `case .french` is a third language that
# will not compile.
while read -r found; do
  [ -z "$found" ] && continue
  case "${found%%:*}" in
    */Domain/Language.swift|*/Domain/LanguagePreference.swift) continue ;;
  esac
  echo "X $found" >&2
  echo "  a language is a catalogue column, not a case to switch on" >&2
  status=1
done <<< "$(grep -rn 'case \.french\|case \.english\|== \.french\|== \.english' \
             Packages/*/Sources --include="*.swift" 2>/dev/null || true)"


# -- A build must not edit a committed catalogue -----------------------------
#
# With `SWIFT_EMIT_LOC_STRINGS` on (Xcode's default), every compile scans the
# source for string literals and writes them into each `.xcstrings` it can find,
# in state `new`. One build produced `%lld`, `%@ - %@` and an empty key across
# ten catalogues -- entries nothing reads, which this very script then refuses,
# from a step nobody ran on purpose.
#
# It is noise by construction here: nothing resolves a key through SwiftUI's
# automatic lookup. It goes through `TextCatalogue`, in the language the content
# was served in, which the extractor knows nothing about.
if ! grep -q "SWIFT_EMIT_LOC_STRINGS: NO" project.yml; then
  echo "X project.yml no longer turns off SWIFT_EMIT_LOC_STRINGS" >&2
  echo "  a build will start writing extracted literals into the catalogues" >&2
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "Text lives in a catalogue. A view names a key." >&2
  exit 1
fi

total="$(python3 -c "
import json, pathlib
print(sum(len(json.loads(p.read_text()).get('strings', {}))
          for p in pathlib.Path('Packages').rglob('*.xcstrings')
          if '.build' not in p.parts))")"
echo "✓ $total entries, every one translated and every one reached."
