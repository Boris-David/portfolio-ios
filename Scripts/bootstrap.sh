#!/usr/bin/env bash
#
# Puts Xcode into a state that matches the repository.
#
#   ./Scripts/bootstrap.sh            regenerate and resolve
#   ./Scripts/bootstrap.sh --open     …and open the project
#
# ## Why this exists
#
# The `.xcodeproj` is generated and not committed, so it is **always** stale
# after a checkout, a rebase, or any change to `project.yml` or the package
# layout. Running `xcodegen generate` is not enough on its own: Xcode keeps its
# own resolved package graph in DerivedData, and when the set of packages
# changes underneath it, the ones it cannot reconcile appear as **blue folders**
# with no contents, and `import Composition` answers "No such module" — while
# `xcodebuild` from the command line builds the same project without complaint.
#
# That happened, and it cost an afternoon of looking in the wrong place. The
# project was correct the whole time; the IDE's cache was not.
#
# So: one command that rebuilds every derived thing in the right order, and
# leaves nothing half-old.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OPEN=false
[ "${1:-}" = "--open" ] && OPEN=true

if pgrep -xq Xcode; then
  echo "⚠️  Xcode is running. It holds the package graph open, so it will keep" >&2
  echo "   serving the stale one. Quit it (⌘Q) and run this again." >&2
  exit 1
fi

echo "── the project, from project.yml"
xcodegen generate >/dev/null
echo "   ✓ Amissan.xcodeproj"

# The lockfile lives inside the generated project and IS committed — it is the
# version lock, not an artefact. `xcodegen` does not touch it, but a `rm -rf` of
# the project directory would, so it is restored explicitly.
LOCK="Amissan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$LOCK" ] && git cat-file -e "HEAD:$LOCK" 2>/dev/null; then
  mkdir -p "$(dirname "$LOCK")"
  git show "HEAD:$LOCK" > "$LOCK"
  echo "   ✓ Package.resolved restored from the index"
fi

echo "── the stale resolved graph"
# Scoped to this project: deleting all of DerivedData is somebody else's
# afternoon.
rm -rf ~/Library/Developer/Xcode/DerivedData/Amissan-*
echo "   ✓ DerivedData for Amissan"

echo "── resolving packages"
xcodebuild -resolvePackageDependencies -project Amissan.xcodeproj 2>&1 \
  | grep -E "^resolved source packages|error" || true

echo
echo "✓ ready. Nine local packages, four remote."
$OPEN && open Amissan.xcodeproj
