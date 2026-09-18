#!/usr/bin/env bash
#
# Régénère la graine embarquée depuis l'API.
#
# La graine est ce que l'application affiche au tout premier lancement, sans
# réseau. Elle n'est JAMAIS écrite à la main : ce serait une seconde source de
# vérité, exactement ce que l'architecture supprime partout ailleurs.
#
#   ./Scripts/seed.sh            régénère
#   ./Scripts/seed.sh --check    échoue si la graine a dérivé de l'API
#
# Le mode `--check` tourne en CI : il transforme « on pense à régénérer » d'une
# discipline en une garde. Il compare la **forme**, pas les valeurs — le contenu
# a le droit de changer sans qu'on republie l'application.
set -euo pipefail

API="${API_BASE_URL:-https://api.amissan.dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/Packages/AmissanKit/Sources/Adapters/Resources"
CHECK=false
[ "${1:-}" = "--check" ] && CHECK=true

shape() {
  # L'ensemble des chemins typés, index de liste effacés : `experience[0].start`
  # et `experience[2].start` décrivent la même forme.
  python3 -c '
import json, sys
def walk(value, path="", into=None):
    into = set() if into is None else into
    if isinstance(value, list):
        for item in value: walk(item, path + "[]", into)
    elif isinstance(value, dict):
        for key, child in value.items(): walk(child, key if path == "" else f"{path}.{key}", into)
    else:
        into.add(f"{path}: {'"'"'null'"'"' if value is None else type(value).__name__}")
    return into
print("\n".join(sorted(walk(json.load(sys.stdin)))))'
}

status=0
for lang in fr en; do
  file="$DEST/seed-$lang.json"
  served="$(curl -fsS "$API/v1/portfolio?lang=$lang")"

  if [ "$CHECK" = false ]; then
    printf '%s' "$served" | python3 -m json.tool --no-ensure-ascii > "$file"
    version="$(printf '%s' "$served" | python3 -c 'import json,sys; print(json.load(sys.stdin)["meta"]["contentVersion"])')"
    echo "✓ seed-$lang.json régénéré — contenu $version"
    continue
  fi

  if [ ! -f "$file" ]; then
    echo "✖ $file absent — lancer ./Scripts/seed.sh" >&2
    status=1
    continue
  fi

  ecart="$(diff <(shape < "$file") <(printf '%s' "$served" | shape) || true)"
  if [ -n "$ecart" ]; then
    echo "✖ seed-$lang.json a dérivé de la forme servie par l'API :" >&2
    echo "$ecart" | head -20 >&2
    echo "  Corriger : ./Scripts/seed.sh" >&2
    status=1
  else
    echo "✓ seed-$lang.json décrit encore la forme servie par l'API"
  fi
done
exit "$status"
