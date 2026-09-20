#!/usr/bin/env bash
#
# Exécute toutes les suites de tests du paquet, plus celle de l'application.
#
#   ./Scripts/test.sh                 sur le simulateur par défaut
#   ./Scripts/test.sh "iPhone 16 Pro" sur un appareil nommé
#
# A script rather than a single scheme: the test targets of a referenced SPM
# package do not enter an app scheme's `test` action. Each suite has its own
# scheme, and this is where they are gathered.
#
# None of these has a declared scheme: XcodeGen cannot declare one for a package
# test target — it reads `A/B` as `project/target` and rejects the spec.
# `xcodebuild` resolves package test targets as implicit schemes anyway, which is
# why listing them here works.
#
# Le code de retour est celui du **premier échec**, pas celui de la dernière
# commande : sans ça, une suite rouge suivie d'une verte rendrait zéro.
set -uo pipefail

DEVICE="${1:-iPhone 17 Pro}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SUITES=(
  DomainTests
  NetworkingTests
  CoreTests
  DataTests
  PresentationTests
  DesignSystemTests
  LocalizationTests
  CoreUITests
  ViewKitTests
  DecisionsTests
  FeatureEngineeringTests
  Amissan
)

status=0
for suite in "${SUITES[@]}"; do
  printf '── %-20s ' "$suite"
  # ⚠️ `SWIFT_EMIT_LOC_STRINGS=NO` sur la ligne de commande, en plus du réglage
  # de `project.yml`.
  #
  # Le réglage au niveau projet suffit pour `xcodebuild build`, et **pas** pour
  # `xcodebuild test` : l'action de test réactive l'extraction automatique des
  # chaînes, qui réécrit alors chaque `.xcstrings` versionné — `%lld`,
  # `%@ · %@`, des entrées marquées `new`. Lancer la suite salissait donc le
  # dépôt, et c'est arrivé jusque dans un commit.
  #
  # Une surcharge en ligne de commande gagne sur tout le reste. Vérifié en
  # relançant la suite et en regardant `git status`.
  sortie="$(xcodebuild test \
    -project Amissan.xcodeproj \
    -scheme "$suite" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    SWIFT_EMIT_LOC_STRINGS=NO \
    2>&1)"
  code=$?

  # `Test run with N tests` vient de swift-testing ; `Executed N tests` de XCTest.
  compte="$(printf '%s' "$sortie" | grep -oE 'Test run with [0-9]+ test' | tail -1 | grep -oE '[0-9]+')"
  [ -z "$compte" ] && compte="$(printf '%s' "$sortie" | grep -oE 'Executed [0-9]+ test' | tail -1 | grep -oE '[0-9]+')"
  if [ "$code" -eq 0 ]; then
    echo "✅ ${compte:-?} tests"
  else
    echo "❌"
    printf '%s\n' "$sortie" | grep -E "error:|✘|failed" | head -12
    status=1
  fi
done

echo
[ "$status" -eq 0 ] && echo "Toutes les suites passent." || echo "Au moins une suite échoue."
exit "$status"
