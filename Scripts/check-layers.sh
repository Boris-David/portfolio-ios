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
  "Core:SwiftUI,UIKit,AppKit,Domain,Networking,Data,Presentation,DesignSystem"
  "DesignSystem:Domain,Presentation,Lottie,Textual,PDFKit,CoreUI"
)

# The rendering libraries are named in exactly one package.
#
# Stated by the author: "I must not have `import Textual` in my code files, but
# `import CoreUI` — so that the day I change library, I do not have to change an
# import."
#
# The manifests already enforce it: no other package declares Lottie or Textual,
# so the import would not resolve. `PDFKit` is different — it ships with the SDK,
# like SwiftUI, so nothing but this guard can keep it in its wrapper.
# ⚠️ `status` is declared here, before the first guard that can set it.
# It used to be declared between the two loops, so the library check found its
# violation, set `status=1` — and the next line reset it to 0. The guard ran,
# reported nothing, and passed. Found by the mutation test, which is the only
# thing that would have found it.
status=0

LIBRARIES="Textual Lottie PDFKit"
for library in $LIBRARIES; do
  hits="$(grep -rln "^import $library\$" Packages --include="*.swift" 2>/dev/null \
    | grep -v '^Packages/CoreUI/' || true)"
  if [ -n "$hits" ]; then
    echo "✖ $library is imported outside CoreUI:" >&2
    printf '    %s\n' $hits >&2
    echo "  Wrap it in CoreUI instead — that is what makes it replaceable." >&2
    status=1
  fi
done

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

# ── `public` means "crosses a package boundary" ─────────────────────────────
#
# `package` is the visibility level everybody forgets, and it is the one that
# matters here: a type shared between two modules of `Features` has no business
# being visible to the application, to a future widget, or to anything else that
# links the package. Marking it `public` to satisfy a neighbour exposes it to
# the world.
#
# So: every public TYPE of `Features` must be named somewhere outside it. If
# nothing outside uses it, it is `package`.
#
# ⚠️ Scoped to `Features` on purpose. Elsewhere the check would cry wolf:
# `HTTPResponse` never appears by name in `Data`, because it arrives through
# type inference from `HTTPClient.send` — and a guard with false positives is a
# guard people learn to skip. Here the public surface is views and environment
# values, which are always named at the point of use.
outside="$(ls -d Packages/*/Sources | grep -v 'Packages/Features/') App/Sources"
for symbol in $(grep -rhoE "^public (struct|enum|final class|class|protocol|actor) [A-Za-z0-9_]+" \
                  Packages/Features/Sources --include="*.swift" | awk '{print $3}' | sort -u); do
  # shellcheck disable=SC2086
  if ! grep -rqw "$symbol" --include="*.swift" $outside 2>/dev/null; then
    echo "✖ Features.$symbol is public but nothing outside the package names it — make it 'package'" >&2
    status=1
  fi
done

# ── Content does not live in a view file ───────────────────────────────────
#
# Stated by the author, looking at a diff: *"strings like that, straight in the
# views — it irritates me no end. Why don't the views only hold keys?"*
#
# They now hold neither. Every decision annotation — bilingual prose about why a
# component was chosen — lives in a `<Feature>Notes.swift` catalogue, and every
# interface label lives in `AppChrome`. A screen names one and renders it.
#
# The numbers are the argument: `ProfileBlocks.swift` was 524 lines of which 330
# were prose, and `ProfileScreen.swift` was 118 lines for a 54-line screen.
#
# This is what keeps them out.
for file in $(grep -rln "DesignDecision(" Packages/Features/Sources --include="*.swift" 2>/dev/null \
                | grep -v "Decisions\.swift$" | grep -v "Sources/Decisions/" || true); do
  echo "✖ $file declares a DesignDecision — content belongs in a <Feature>Decisions.swift" >&2
  status=1
done


# -- The application target wires; it does not draw ---------------------------
#
# The composition root used to be a package, so the app target could only see
# `Composition` and could not write `import Networking` at all. Moving the root
# into the target -- which is what it is, in clean architecture: the one ring
# nobody imports -- gave that up, because assembling the graph is now this
# target's job and it names every layer.
#
# This is what replaces it. The risk was never `import Networking` in a file
# that builds a URLSession; it was somebody writing a *screen* here, where none
# of the Features rules apply. A screen is recognisable: it resolves text.
for file in $(find App/Sources -name "*.swift" 2>/dev/null); do
  if grep -qE 'InterfaceText\.|SettingsText\.|TextKey|@Localized|TextCatalogue' "$file"; then
    echo "X $file resolves text -- the app target assembles, it does not draw" >&2
    echo "  a screen belongs in Packages/Features; this target names one and wires it" >&2
    status=1
  fi
  if grep -qE '(Text|Label|Button)\("[^"\\%]{4,}"' "$file"; then
    echo "X $file writes a sentence -- see Packages/Features and its catalogues" >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "A layer reached for something it must not see. See Scripts/check-layers.sh." >&2
  exit 1
fi

count="$(printf '%s\n' "${RULES[@]}" | wc -l | tr -d ' ')"
echo "✓ $count layers keep to themselves, and 'public' still means public."
