#!/usr/bin/env bash
#
# Refuses the imports that no manifest can refuse.
#
# The package graph holds most of the layering: `Features/Package.swift` never
# names `Networking`, so `import Networking` in a screen does not compile. That
# is the strong form, and it needs no script.
#
# But three modules ship with the SDK — SwiftUI, UIKit, AppKit — and every target
# can import them. So the two invariants that matter most have no manifest to
# hold them:
#
#   - the DOMAIN must not know a user interface exists. It describes what the
#     application *is*; a `Color` in an entity is the end of that;
#   - the PRESENTATION layer must not render. That is the acid test of the
#     layer: if it draws, it is a view. A presenter that imports SwiftUI can
#     only be tested with a renderer, and the whole point of extracting it was
#     that it can be tested with values.
#
# Hence this guard. It is the one place where a rule is held by a grep, and it
# says so.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# layer:forbidden,imports
RULES=(
  "Domain:SwiftUI,UIKit,AppKit,Combine"
  "Presentation:SwiftUI,UIKit,AppKit,DesignSystem"
  "Networking:SwiftUI,UIKit,AppKit,Domain"
  "Persistence:SwiftUI,UIKit,AppKit,Domain"
  "DesignSystem:Domain,Presentation"
)

status=0
for rule in "${RULES[@]}"; do
  layer="${rule%%:*}"
  IFS=',' read -ra forbidden <<< "${rule#*:}"
  sources="Packages/$layer/Sources"
  [ -d "$sources" ] || { echo "✖ $sources does not exist" >&2; status=1; continue; }

  for module in "${forbidden[@]}"; do
    hits="$(grep -rln "^import $module\$" "$sources" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      echo "✖ $layer imports $module:" >&2
      printf '    %s\n' $hits >&2
      status=1
    fi
  done
done

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "A layer reached for something it must not see. See Scripts/check-layers.sh." >&2
  exit 1
fi

count="$(printf '%s\n' "${RULES[@]}" | wc -l | tr -d ' ')"
echo "✓ $count layers keep to themselves."
