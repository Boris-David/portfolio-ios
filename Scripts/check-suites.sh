#!/usr/bin/env bash
#
# Every test target actually runs.
#
# ## The failure this exists for
#
# A test suite does not fail when it stops running. It disappears, quietly, and
# the total at the bottom of the log goes down by a number nobody was counting.
#
# Two ways that happens here, both observed:
#
#   - a package is added to `Packages/` but not to `project.yml`. It still
#     builds, because it is reached transitively — but Xcode never surfaces its
#     test target, and `xcodebuild test -scheme XTests` answers "no such
#     scheme". `CoreUITests` spent an hour in that state;
#   - a test target is added to a manifest but not to `Scripts/test.sh`. It
#     compiles, it is never executed, and it reports nothing.
#
# Both are invisible in a green run. This is what makes them loud.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

# ── Every package is declared to the project ───────────────────────────────
# ⚠️ `.testTarget(name: "X"` on one line is the easy case, and it was the only
# case this guard could see. A target that needs `resources:` or a long
# dependency list gets reformatted onto several lines by the formatter, and then
# it vanished from this check — three suites were invisible here while running
# perfectly well, which is precisely the drift this file exists to catch.
#
# So the name is read from the manifest with the newlines removed.
test_targets_in() {
  tr '\n' ' ' < "$1" \
    | grep -oE '\.testTarget\([[:space:]]*name: "[A-Za-z0-9_]+"' \
    | sed -E 's/.*"([A-Za-z0-9_]+)"/\1/'
}

for manifest in Packages/*/Package.swift; do
  package="$(basename "$(dirname "$manifest")")"
  if ! grep -qE "^  $package:\$" project.yml; then
    echo "✖ package '$package' is missing from project.yml — its test target will not get a scheme" >&2
    status=1
  fi
done

# ── Every test target is in the runner ─────────────────────────────────────
for manifest in Packages/*/Package.swift; do
  while read -r suite; do
    [ -z "$suite" ] && continue
    if ! grep -qE "^  $suite\$" Scripts/test.sh; then
      echo "✖ test target '$suite' is declared but never run — add it to Scripts/test.sh" >&2
      status=1
    fi
  done <<< "$(test_targets_in "$manifest")"
done

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "A suite that stops running does not fail. It vanishes." >&2
  exit 1
fi

count="$(for manifest in Packages/*/Package.swift; do test_targets_in "$manifest"; done | wc -l | tr -d ' ')"
echo "✓ $count test targets, all declared and all run."
