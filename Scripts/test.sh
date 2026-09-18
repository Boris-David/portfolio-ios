#!/usr/bin/env bash
#
# Exécute toutes les suites de tests du paquet, plus celle de l'application.
#
#   ./Scripts/test.sh                 sur le simulateur par défaut
#   ./Scripts/test.sh "iPhone 16 Pro" sur un appareil nommé
#
# Un script plutôt qu'un schéma unique : les cibles de test d'un paquet SPM
# référencé n'entrent pas dans l'action `test` d'un schéma d'application. Chaque
# suite a son propre schéma, généré par Xcode, et c'est ici qu'on les rassemble.
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
  PersistenceTests
  AdaptersTests
  BackstageTests
  DesignSystemTests
  ArchitectureTests
  Amissan
)

status=0
for suite in "${SUITES[@]}"; do
  printf '── %-20s ' "$suite"
  sortie="$(xcodebuild test \
    -project Amissan.xcodeproj \
    -scheme "$suite" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
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
