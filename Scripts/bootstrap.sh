#!/usr/bin/env bash
#
# Puts Xcode into a state that matches the repository.
#
#   ./Scripts/bootstrap.sh                  regenerate and resolve — the fast path
#   ./Scripts/bootstrap.sh --clean          …after wiping this project's DerivedData
#   ./Scripts/bootstrap.sh --open           …and open the project
#   ./Scripts/bootstrap.sh --clean --open   the full reset, which is what fixes it
#
# ## Why this exists
#
# The `.xcodeproj` is generated and not committed, so it is **always** stale
# after a checkout, a rebase, or any change to `project.yml` or the package
# layout. Running `xcodegen generate` alone is not enough: Xcode keeps its own
# resolved package graph in DerivedData, and when the set of packages changes
# underneath it, the ones it cannot reconcile show as **blue folders** with no
# contents while `import Composition` answers "No such module" — and the command
# line builds the very same project without complaining.
#
# That cost an afternoon of looking in the wrong place. The project was correct
# the whole time; the IDE's cache was not. Hence `--clean`, which is the only
# flag that actually fixes that state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CLEAN=false
OPEN=false
for argument in "$@"; do
  case "$argument" in
    --clean) CLEAN=true ;;
    --open) OPEN=true ;;
    -h|--help) sed -n '3,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $argument" >&2; exit 2 ;;
  esac
done

# Xcode holds the package graph open, so it would keep serving the stale one —
# and on `--clean` it would write its cache back out while we delete it.
if pgrep -xq Xcode; then
  echo "── Xcode is running, and it holds the graph open"
  osascript -e 'quit app "Xcode"' >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do pgrep -xq Xcode || break; sleep 0.5; done
  if pgrep -xq Xcode; then
    echo "   ✖ it would not quit — an unsaved document is probably waiting." >&2
    echo "     Quit it by hand (⌘Q) and run this again." >&2
    exit 1
  fi
  echo "   ✓ quit"
  # It was open, so the reader expects to get it back.
  OPEN=true
fi

if $CLEAN; then
  echo "── the stale resolved graph"
  # Scoped to this project: deleting all of DerivedData is somebody else's
  # afternoon.
  rm -rf ~/Library/Developer/Xcode/DerivedData/Amissan-*
  echo "   ✓ DerivedData for Amissan"
fi

echo "── the project, from project.yml"
xcodegen generate >/dev/null
echo "   ✓ Amissan.xcodeproj"

# The lockfile lives inside the generated project and IS committed — it is the
# version lock, not an artefact. `xcodegen` leaves it alone, but a `rm -rf` of
# the project directory would not, so it is restored explicitly.
LOCK="Amissan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$LOCK" ] && git cat-file -e "HEAD:$LOCK" 2>/dev/null; then
  mkdir -p "$(dirname "$LOCK")"
  git show "HEAD:$LOCK" > "$LOCK"
  echo "   ✓ Package.resolved restored from the index"
fi

echo "── resolving packages"
xcodebuild -resolvePackageDependencies -project Amissan.xcodeproj 2>&1 \
  | grep -E "^resolved source packages|error" || true

LOCAL=$(grep -c "path: Packages/" project.yml)
echo
echo "✓ ready. $LOCAL local packages."
$OPEN && open Amissan.xcodeproj
