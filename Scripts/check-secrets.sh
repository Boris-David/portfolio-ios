#!/usr/bin/env bash
#
# Refuse un secret ou un marqueur d'employeur dans le contenu versionné.
#
# Le dépôt est **public** et l'historique est irréversible : une fois poussé,
# c'est poussé. Le hook de pre-commit du workspace fait le même travail sur ce
# qui est indexé ; ce script le refait en CI, sur l'arbre entier — parce qu'un
# hook local ne survit pas à un clone ailleurs.
#
# ⚠️ Les motifs sont **assemblés à l'exécution** : écrits en clair, ce fichier
# se refuserait lui-même, et l'exempter ouvrirait un trou dans la garde.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DASHES="$(printf -- '-%.0s' 1 2 3 4 5)"
EMPLOYEUR="instant""-system"".com"
ESN="ine""tum"".com"

PATTERNS=(
  "$EMPLOYEUR"
  "$ESN"
  "${DASHES}BEGIN [A-Z ]*PRIV""ATE KEY${DASHES}"
  'ghp_[A-Za-z0-9]{36}'
  'gho_[A-Za-z0-9]{36}'
  'AIza[0-9A-Za-z_-]{35}'
  'sk-[A-Za-z0-9]{20,}'
  # Une clé App Store Connect, qui n'a rien à faire ici.
  'AuthKey_[A-Z0-9]{10}\.p8'
)

trouve=0
fichiers="$(git ls-files)"

while IFS= read -r fichier; do
  [ -f "$fichier" ] || continue
  # Ce script porte les motifs : il ne s'examine pas lui-même.
  case "$fichier" in Scripts/check-secrets.sh) continue ;; esac
  # Les actifs binaires n'ont pas de texte à fouiller.
  case "$fichier" in *.png|*.jpg|*.jpeg|*.pdf|*.mobileprovision) continue ;; esac

  for motif in "${PATTERNS[@]}"; do
    # `-e` : un motif commençant par « - » serait lu comme des options par grep,
    # qui échouerait — et un échec de grep se confond avec « rien trouvé ».
    if grep -Eq -e "$motif" "$fichier" 2>/dev/null; then
      echo "✖ motif interdit dans $fichier" >&2
      echo "  → $motif" >&2
      trouve=1
    fi
  done
done <<< "$fichiers"

if [ "$trouve" -ne 0 ]; then
  echo "Le dépôt est public : ces marqueurs ne doivent jamais y entrer." >&2
  exit 1
fi

compte="$(printf '%s\n' "$fichiers" | wc -l | tr -d ' ')"
echo "✓ aucun secret ni marqueur d'employeur dans $compte fichiers versionnés."
