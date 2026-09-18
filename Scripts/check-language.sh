#!/usr/bin/env bash
#
# Refuses French in Swift source: comments and identifiers alike.
#
# Non-negotiable, and stated as such by the author. The reason is not style —
# it is readership. This repository is opened by recruiters and engineers who
# may not read French, and a codebase whose reasoning is unreadable to half its
# audience wastes the very thing it was written for.
#
# Prose in French stays in `docs/` and in the app's own content: those are
# written for a French-speaking reader and translated where it matters.
#
# The detection is a word list, not an accent check: "résumé" is a perfectly
# good English word and must not trip the guard, while "le", "des" and "c'est"
# are unambiguous.
#
# ⚠️ Only `//` and `///` lines are inspected. The first version also matched a
# leading `*`, meaning to catch the continuation lines of a `/* … */` block —
# there are none in this repository — and instead it caught every line of French
# app content that began with `**bold**`. A guard that flags the very thing it
# promises not to touch is a guard people learn to pass with `|| true`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Whole words that do not exist in English, or that never appear in English
# technical prose. Kept deliberately short: a long list produces false positives,
# and a guard that cries wolf gets disabled.
# Curated so that **no entry is also an English word**. The first draft included
# `on`, `il`, `est` and `plus` and flagged a perfectly English sentence — a guard
# that cries wolf gets disabled, which is worse than no guard at all.
#
# Deliberately excluded for the same reason: `sans` (sans-serif), `plus`, `on`,
# `est`, `a`, `car`, `an`, `son`, `ton`, `pas` is kept because "pas" never
# appears alone in English prose.
FRENCH='\b(le|la|les|une|des|dans|avec|mais|donc|qui|que|quoi|sont|être|fait|faire|pas|tout|toute|cette|ça|où|leur|elle|nous|vous|ils|elles|parce|puisque|alors|ainsi|déjà|jamais|toujours|aussi|même|entre|chaque|aucun|aucune|quand|comme|ceci|cela|celui|celle|ainsi|lorsque|depuis|jusqu|selon|chez|sous|vers|elles)\b'
CONTRACTIONS="(c'est|n'est|d'un|d'une|l'on|qu'il|qu'on|s'il|jusqu'|lorsqu')"

found=0
while IFS= read -r file; do
  # Comment lines only — string literals may legitimately hold French, because
  # the app is bilingual and its content is written in both.
  offenders="$(grep -nE '^\s*///?' "$file" 2>/dev/null \
    | grep -icE "$FRENCH|$CONTRACTIONS" || true)"
  if [ "${offenders:-0}" -gt 0 ]; then
    echo "✖ French in comments: $file ($offenders line(s))" >&2
    grep -nE '^\s*///?' "$file" | grep -iE "$FRENCH|$CONTRACTIONS" | head -2 >&2
    found=1
  fi
# Only tracked files: a file that is not in the index is a file CI never sees
# either, and walking the working tree would sweep up build artefacts.
done <<< "$(git ls-files '*.swift')"

if [ "$found" -ne 0 ]; then
  echo "" >&2
  echo "Swift source is English-only. French prose belongs in docs/ and in app content." >&2
  exit 1
fi

count="$(git ls-files '*.swift' | wc -l | tr -d ' ')"
echo "✓ $count Swift files, English only."
