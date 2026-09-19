#!/usr/bin/env bash
#
# The name says the role.
#
# Stated by the author: *"everything that is a network request must be suffixed
# `Request`, same for responses, for adapters `Adapter`, for screens `Screen`."*
#
# The rule, in one sentence: **the suffix names the role in the architecture,
# never the Swift kind.** `PortfolioEntity` and `LanguageEnum` add a word that
# says nothing — every type is a type. `PortfolioDTO` says which layer it belongs
# to and what it does.
#
# Two deliberate exceptions, both documented in docs/refonte.md §21:
#
#   - ENTITIES carry no suffix. The domain speaks the business's vocabulary, and
#     the business does not say "PortfolioEntity";
#   - PROTOCOLS follow Swift, not us. The API Design Guidelines are explicit: a
#     protocol describing a capability is named in -able, -ible or -ing.
#     `PortfolioReading` reads at the point of use; `PortfolioPort` only says it
#     exists.
#
# A convention nothing executes lasts three weeks. This is what executes it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

# Declarations in a directory, excluding nested ones (indented) and protocols,
# which follow Swift's own convention.
declarations() {
  grep -rhoE "^(public |package |private )?(struct|enum|final class|class|actor) [A-Za-z0-9_]+" \
    "$1" --include="*.swift" 2>/dev/null | awk '{print $NF}' | sort -u
}

# directory|allowed suffixes (regex alternation)|what the layer is
RULES=(
  "Packages/Data/Sources/Data/DTO|DTO|the wire format"
  "Packages/Data/Sources/Data|Repository|Mapper|DataSource|Endpoints|Error|Providing|the data layer"
  "Packages/Networking/Sources/Networking|Request|Response|Client|Error|Headers|Download|Disposition|the transport"
)

check() {
  local directory="$1" suffixes="$2" what="$3" maxdepth="${4:-}"
  local found
  if [ "$maxdepth" = "flat" ]; then
    found="$(grep -hoE "^(public |package |private )?(struct|enum|final class|class|actor) [A-Za-z0-9_]+" \
      "$directory"/*.swift 2>/dev/null | awk '{print $NF}' | sort -u)"
  else
    found="$(declarations "$directory")"
  fi
  for name in $found; do
    if ! printf '%s' "$name" | grep -qE "($suffixes)\$"; then
      echo "✖ $what: '$name' should end in one of: ${suffixes//|/, }" >&2
      status=1
    fi
  done
}

check "Packages/Data/Sources/Data/DTO"            "DTO" "the wire format"
check "Packages/Data/Sources/Data"                "Repository|Mapper|DataSource|Endpoints|Error|Providing" "the data layer" flat
check "Packages/Networking/Sources/Networking"    "Request|Response|Client|Error|Headers|Download|Disposition" "the transport"

# ── Views: a closed vocabulary of UI roles ─────────────────────────────────
#
# A screen reads the app's state; everything else receives what it draws. Both
# say so in their name, and the list is closed on purpose — a new role has to
# justify joining it, which is the point of having one.
# `Image` joined the list on 2026-09-18 for `ContentImage`, and the reasoning is
# the bar for joining it: it names a kind of view exactly as `Card` and `Banner`
# do, and `ContentImageView` would say "view" twice. A role that cannot be
# argued for does not get added — a list widened whenever it fires is a list
# that stops meaning anything.
# `Label` joined on 2026-09-18 for `SectionLabel`, and the reasoning is the bar
# for joining: it names a kind of view exactly as `Card` and `Banner` do — a
# word and a glyph, together — and `SectionLabelView` would say "view" twice.
# `Section` joined on 2026-09-19, with the app's first `List`. It names a kind of
# view exactly as `Row` and `Cell` do — the group they sit in, with its header —
# and it only became sayable once a list existed to put one in.
# `Behaviour` joined the same day, for a `ViewModifier` that changes what a view
# **does** rather than how it looks: `.returningToTop()` adds a response to a
# gesture and draws nothing. The alternative was `ReturnToTopModifier`, which
# names the Swift kind — the one thing this whole convention exists to refuse —
# on a type that already conforms to `ViewModifier`.
VIEW_ROLES="Screen|View|Block|Card|Cell|Row|Sheet|Section|Overlay|Banner|Shell|Style|Group|Image|Label|Behaviour"
for name in $(grep -rhoE "^(public |package |private )?struct [A-Za-z0-9_]+(<[^>]*>)?: (View|ViewModifier)" \
                Packages/Features/Sources --include="*.swift" \
                | sed -E 's/.*struct ([A-Za-z0-9_]+).*/\1/' | sort -u); do
  if ! printf '%s' "$name" | grep -qE "($VIEW_ROLES)\$"; then
    echo "✖ a feature view: '$name' should end in one of: ${VIEW_ROLES//|/, }" >&2
    status=1
  fi
done

# ── Test doubles say what kind of double they are ──────────────────────────
#
# `Stub` answers what it was told to. `Spy` also records what it was asked.
# A double called `MemoryStore` reads like production code, and that is exactly
# how a double ends up shipped.
for name in $(grep -rhoE "^(struct|final class|actor) [A-Za-z0-9_]+" Packages/*/Tests --include="*.swift" \
                | awk '{print $NF}' | sort -u | grep -v "Tests$"); do
  if ! printf '%s' "$name" | grep -qE "(Stub|Spy|Fake)$"; then
    echo "✖ a test double: '$name' should end in Stub, Spy or Fake" >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "The name says the role. See docs/refonte.md §21." >&2
  exit 1
fi

echo "✓ every type wears the suffix of its role."
