#!/usr/bin/env bash
#
# Captures every screen, in every combination that can break it.
#
#   ./Scripts/screens.sh                    the default matrix
#   ./Scripts/screens.sh --device "iPad Pro 13-inch (M4)"
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

while [ $# -gt 0 ]; do
  case "$1" in
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
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
rm -f "$OUT"/*.png

# tab | extra launch flags
SCREENS=(
  "profile|"
  "work|"
  "journey|"
  "backstage|-backstage"
  "profile|-settings"
  "profile|-resume"
)

capture() {
  local tab="$1" flags="$2" appearance="$3" size="$4" name="$5"
  xcrun simctl ui "$UDID" appearance "$appearance" >/dev/null
  xcrun simctl ui "$UDID" content_size "$size" >/dev/null
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  # shellcheck disable=SC2086
  xcrun simctl launch "$UDID" "$BUNDLE" -tab "$tab" $flags >/dev/null
  sleep 6
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1
  printf '  %s\n' "$name"
}

echo "── the default matrix, on $DEVICE_NAME"
for entry in "${SCREENS[@]}"; do
  tab="${entry%%|*}"; flags="${entry#*|}"
  label="$tab${flags:+${flags// /}}"
  capture "$tab" "$flags" dark large  "${label}-dark"
  capture "$tab" "$flags" light large "${label}-light"
done

echo "── at accessibility5, where a layout falls apart"
for entry in "${SCREENS[@]}"; do
  tab="${entry%%|*}"; flags="${entry#*|}"
  label="$tab${flags:+${flags// /}}"
  capture "$tab" "$flags" dark accessibility5 "${label}-ax5"
done

# Leave the simulator as it was found: a device left at accessibility5 makes the
# next person's screenshots look broken for a reason they will not guess.
xcrun simctl ui "$UDID" content_size large >/dev/null
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true

echo
echo "✓ $(ls "$OUT"/*.png | wc -l | tr -d ' ') captures in $OUT"
echo "  They are not committed — look at them, then throw them away."
