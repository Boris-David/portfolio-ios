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

# ── Refus par CHEMIN, avant même de regarder le contenu ──────────────────────
#
# Un fichier de signature se reconnaît à son extension, et le refuser par son nom
# attrape le cas où son contenu ne ressemblerait à aucun motif connu — une clé
# chiffrée, un format propriétaire, un fichier tronqué.
#
# Motivé par un incident réel le 2026-09-18 : une clé APNs a été déposée dans
# l'arbre de ce dépôt. `.gitignore` l'a retenue, donc rien n'a fuité — mais un
# `git add -f` suffisait, et une clé poussée sur un dépôt public est irréversible.
INTERDITS_PAR_EXTENSION='\.(p8|p12|cer|mobileprovision|certSigningRequest|keystore|jks)$'

while IFS= read -r fichier; do
  if printf '%s' "$fichier" | grep -Eq "$INTERDITS_PAR_EXTENSION"; then
    echo "✖ matériel de signature versionné : $fichier" >&2
    echo "  Ces fichiers ne s'ajoutent jamais à un dépôt : ils vivent dans le" >&2
    echo "  trousseau, dans les secrets GitHub, ou dans le dépôt privé de match." >&2
    trouve=1
  fi
done <<< "$fichiers"

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
