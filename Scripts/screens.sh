#!/usr/bin/env bash
#
# Captures every screen, in every combination that can break it.
#
#   ./Scripts/screens.sh                    the default matrix
#   ./Scripts/screens.sh --device "iPad Pro 13-inch (M4)"
#   ./Scripts/screens.sh --only work        just the entries whose label matches
#   ./Scripts/screens.sh --only work --sizes light
#
# `--only` and `--sizes` exist so that nobody writes their own capture loop
# while iterating on one screen. Somebody did, during the UI rebuild, and it
# silently re-photographed the previous screen twice: `simctl terminate` returns
# before the process exits, and the hand-rolled wait was subtly wrong. The
# script already knows that; a shortcut through it does not.
#
# ## Why a script and not a checklist
#
# Six defects in this code base were invisible in a build and obvious in a
# screenshot: the missing `UILaunchScreen` running the app in compatibility mode,
# an annotation that erased its neighbours, a Lottie anchor pointing at an empty
# band, French chrome over English content, a prominent button unreadable on
# iOS 18, and — while fixing that one — a label that vanished on iOS 26.
#
# None of them produced a warning. A checklist would have caught them only if
# somebody ran it, in the right language, on the right theme, at the right text
# size. That is nine combinations per screen, which nobody does twice.
#
# ## The matrix, and why each axis is on it
#
# - **language**: the app's chrome follows the *content*, not the device. The two
#   have disagreed on screen before;
# - **appearance**: every colour is declared in both themes, and a colour defined
#   for one is unreadable on the other;
# - **text size**: `accessibility5` is where a layout that only ever ran at
#   `large` falls apart. `ViewThatFits` exists because of it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVICE_NAME="iPhone 17 Pro"
OUT="$ROOT/.screens"
BUNDLE="dev.amissan.portfolio"
ONLY=""
SIZES="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --sizes) SIZES="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

UDID="$(xcrun simctl list devices available --json \
  | python3 -c "
import json,sys
name = sys.argv[1]
for runtime, devices in json.load(sys.stdin)['devices'].items():
    for device in devices:
        if device['name'] == name:
            print(device['udid']); raise SystemExit
raise SystemExit('no device named ' + name)
" "$DEVICE_NAME")"

APP="$(find ~/Library/Developer/Xcode/DerivedData -name 'Amissan.app' \
  -path '*Debug-iphonesimulator*' -maxdepth 6 2>/dev/null | head -1)"
[ -n "$APP" ] || { echo "✖ build the app first" >&2; exit 1; }

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
# A clean slate, once.
#
# Preferences survive a reinstall of the binary but not an uninstall, and a
# matrix that inherits whatever the last run left behind is not a matrix. The
# capture flags themselves no longer write anything — that was a defect, found
# exactly here — but the reader's own settings would still leak in.
xcrun simctl uninstall "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"

mkdir -p "$OUT"
# A narrowed run keeps what it is not re-taking: the point of `--only` is to
# compare one screen against the rest of the matrix.
[ -n "$ONLY" ] || rm -f "$OUT"/*.png

# tab | extra launch flags
SCREENS=(
  "profile|"
  "work|"
  "journey|"
  "product|"
  "work|-decisions"
  # Annotations on a tab that is a `List`, and on a pushed screen. Both were
  # broken in ways no other combination could show: the numbering renumbered
  # itself as lazy rows recycled, and the sheet was presented by whichever of
  # five anchors SwiftUI happened to pick.
  "journey|-decisions"
  # The profile carries a note on the scroll view itself — the case that used to
  # draw a dashed rectangle around the whole screen.
  "profile|-decisions"
  "work|-decisions -route caseStudy:mobile-ticketing"
  "profile|-modal settings"
  # Settings **with** the annotations on.
  #
  # The mode was captured on one tab and the settings sheet was captured with
  # the mode off, so the one combination nobody had was the one that mattered:
  # this screen emitted three annotations that nothing drew, because a sheet is
  # its own view tree and had never been given a `.decisionOverlay()`. Neither
  # of the two captures could show it; their intersection does.
  "profile|-modal settings -decisions"
  "profile|-modal resume"
  # The contact sheet: a screen of the app the matrix could not reach at all,
  # because it was the one modal without a flag of its own.
  "profile|-modal contact"
  # A pushed screen needs the route flag: a tab flag cannot reach it, and
  # without this the comparison table — the one screen a `Grid` exists for —
  # is the only one the matrix never sees.
  "work|-route engineering"
  "work|-route architectures"
  # The destination of the zoom transition, and the longest reading in the app.
  # It was not on the matrix, so neither the disclosure rows nor the gallery
  # were ever photographed.
  "work|-route caseStudy:mobile-ticketing"
  # The two readings the profile pushes. Neither was on the matrix, and one of
  # them — the deep dive — rendered **nothing at all** for weeks behind a card
  # a reader reaches by touching it.
  # The product detail is **presented** from the list, so this entry is the
  # only way it is ever captured.
  "product|-route product:kcalories"
  "product|-route product:portfolio"
  "profile|-route about"
  "profile|-modal personality"
  "profile|-route expertise:concurrency"
)

# ⚠️ `xcrun simctl ui … content_size` exits **0** on a value it rejects.
#
# The first version of this script passed `accessibility5`, which simctl prints
# "Invalid argument" for and then reports success. `set -euo pipefail` never
# fired, eighteen files were written, and the whole accessibility axis was
# silently captured at the previous size. The captures looked plausible, which is
# why nobody would have caught it by eye.
#
# So the value is read back and compared. The lesson is the repository's own: a
# tool's exit code is a claim, and the observable result is the evidence.
set_content_size() {
  local wanted="$1"
  xcrun simctl ui "$UDID" content_size "$wanted" >/dev/null 2>&1
  local actual
  actual="$(xcrun simctl ui "$UDID" content_size 2>/dev/null | tr -d '[:space:]')"
  if [ "$actual" != "$wanted" ]; then
    echo "✖ content_size stayed at '$actual' after asking for '$wanted'" >&2
    echo "  simctl reports success on values it rejects — see the comment above." >&2
    exit 1
  fi
}

# Waits until the app is really gone.
#
# WARNING: `simctl terminate` returns before the process has exited. Launching
# straight after it finds the old instance still alive, and `launch` then simply
# **foregrounds** it -- the flags are ignored and the screenshot shows the
# previous screen. Every capture still lands, every file is the wrong size, and
# nothing anywhere says so.
#
# This is the second time this matrix has lied: the first was `content_size`,
# which `simctl` accepts with exit 0 and silently ignores. Same lesson, so the
# same answer -- do not trust the exit code, check the state.
wait_until_gone() {
  local attempt
  for attempt in $(seq 1 40); do
    xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE" || return 0
    sleep 0.25
  done
  echo "  the app would not quit; the capture would show the previous screen" >&2
  return 1
}

capture() {
  local tab="$1" flags="$2" appearance="$3" size="$4" name="$5"
  xcrun simctl ui "$UDID" appearance "$appearance" >/dev/null
  set_content_size "$size"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  wait_until_gone || return 1
  # shellcheck disable=SC2086
  xcrun simctl launch "$UDID" "$BUNDLE" -tab "$tab" $flags >/dev/null
  sleep 6
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1
  printf '  %s\n' "$name"
}

# ⚠️ `grep -E`, and a count checked at the end.
#
# With plain `grep`, `--only "about|expertise"` matched **neither**: macOS ships
# BSD grep, whose basic expressions have no alternation, so the pattern was
# taken literally. The run printed one capture, exited 0, and said nothing about
# the half it had skipped — which is the same failure mode as `content_size`
# accepting a value it ignores, one layer up.
selected() { [ -z "$ONLY" ] || printf '%s' "$1" | grep -Eq "$ONLY"; }
matched=0

echo "── the default matrix, on $DEVICE_NAME"
for entry in "${SCREENS[@]}"; do
  tab="${entry%%|*}"; flags="${entry#*|}"
  label="$tab${flags:+${flags// /}}"
  selected "$label" || continue
  matched=$((matched + 1))
  [ "$SIZES" = "light" ] || capture "$tab" "$flags" dark large "${label}-dark"
  capture "$tab" "$flags" light large "${label}-light"
done

if [ "$SIZES" != "light" ]; then
  echo "── at the largest accessibility size, where a layout falls apart"
  for entry in "${SCREENS[@]}"; do
    tab="${entry%%|*}"; flags="${entry#*|}"
    label="$tab${flags:+${flags// /}}"
    selected "$label" || continue
    capture "$tab" "$flags" dark accessibility-extra-extra-extra-large "${label}-ax5"
  done
fi

if [ -n "$ONLY" ] && [ "$matched" -eq 0 ]; then
  echo "✖ --only '$ONLY' matched no screen. Labels look like 'profile-routeabout'." >&2
  exit 1
fi

# Leave the simulator as it was found: a device left at accessibility5 makes the
# next person's screenshots look broken for a reason they will not guess.
set_content_size large
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true

echo
echo "✓ $(ls "$OUT"/*.png | wc -l | tr -d ' ') captures in $OUT"
echo "  They are not committed — look at them, then throw them away."
