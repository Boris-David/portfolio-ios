#!/usr/bin/env python3
"""Compose le catalogue d'actifs de l'application.

    ./Scripts/assets.py            reconstruit le catalogue
    ./Scripts/assets.py --check    échoue si un actif attendu manque

Deux familles d'actifs, deux provenances, et la distinction compte :

* **l'icône de l'application** est *générée* depuis `design/tokens.json` — la
  même source que le favicon du site, donc exactement la même identité. Aucune
  couleur n'est recopiée ;
* **les icônes d'applications et les captures** sont *importées* depuis
  `portfolio-web`, où elles sont déjà publiées. Elles sont ensuite **versionnées
  ici** : un clone isolé de ce dépôt — donc la CI — doit pouvoir construire sans
  aller chercher un dépôt voisin.

Ce n'est pas une seconde source de vérité : chaque client embarque
nécessairement ses propres octets. Le **contrat**, lui, est le slug servi par
l'API, et `tests/` vérifie que chaque slug rendu a son fichier.
"""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "design" / "tokens.json"
# Two catalogues, and the split is deliberate.
#
# CONTENT — operator logos, product screenshots — lives with the layer that
# draws it. The app target holds only what makes it an app.
CATALOG = ROOT / "Packages" / "Features" / "Sources" / "ViewKit" / "Resources" / "Content.xcassets"
# IDENTITY — the app icon — must stay in the application's own catalogue:
# `ASSETCATALOG_COMPILER_APPICON_NAME` resolves against it and nowhere else.
APP_CATALOG = ROOT / "App" / "Resources" / "Assets.xcassets"
WEB = ROOT.parent / "web" / "public"
# Le slug que l'API donne à cette application elle-même, et le côté des icônes
# publiées dans `portfolio-web` — la vignette générée doit leur ressembler.
OWN_SLUG = "portfolio"
OWN_ICON_SIDE = 132

CHECK = "--check" in sys.argv


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


# ─────────────────────────────────────────────────────────────────────────────
# L'icône de l'application
# ─────────────────────────────────────────────────────────────────────────────

def draw_app_icon(tokens: dict, size: int = 1024) -> Image.Image:
    """Le monogramme du site, redessiné à la taille demandée.

    Les coordonnées viennent du tracé SVG du favicon, exprimé dans une grille
    de 64. Les reprendre telles quelles garantit la même forme — un « A » \
    redessiné à l'œil aurait été « presque » le même, ce qui se voit quand les \
    deux se croisent dans un onglet de navigateur.

    Pas de coins arrondis, pas de transparence : le système applique lui-même \
    son masque, et un coin arrondi peint à l'avance ressort doublé.
    """
    background = hex_to_rgb(tokens["color"]["accent"]["light"])
    letter = hex_to_rgb(tokens["color"]["on-accent"]["light"])
    scale = size / 64

    image = Image.new("RGB", (size, size), background)
    draw = ImageDraw.Draw(image)

    def scaled(points: list[tuple[float, float]]) -> list[tuple[float, float]]:
        return [(x * scale, y * scale) for x, y in points]

    # Le « A » : silhouette extérieure, puis le contrepoinçon repeint au fond.
    # `fill-rule: evenodd` du SVG produit le même résultat sur un fond opaque.
    draw.polygon(
        scaled([(32, 13), (49, 51), (40.8, 51), (37.5, 43.4),
                (26.5, 43.4), (23.2, 51), (15, 51)]),
        fill=letter,
    )
    draw.polygon(scaled([(32, 27.9), (28.5, 36.2), (35.5, 36.2)]), fill=background)
    return image


def build_app_icon(tokens: dict) -> list[str]:
    target = APP_CATALOG / "AppIcon.appiconset"
    png = target / "icon-1024.png"
    problems: list[str] = []

    if CHECK:
        if not png.exists():
            problems.append("AppIcon manquante — lancer ./Scripts/assets.py")
        return problems

    target.mkdir(parents=True, exist_ok=True)
    draw_app_icon(tokens).save(png, format="PNG", optimize=True)
    write_json(
        target / "Contents.json",
        {
            "images": [{"filename": "icon-1024.png", "idiom": "universal",
                        "platform": "ios", "size": "1024x1024"}],
            "info": {"author": "xcode", "version": 1},
        },
    )
    print(f"✓ AppIcon générée depuis design/tokens.json ({png.stat().st_size // 1024} Ko)")
    return problems


# ─────────────────────────────────────────────────────────────────────────────
# Les actifs importés
# ─────────────────────────────────────────────────────────────────────────────

def import_imageset(name: str, source: Path, scale_free: bool = True) -> None:
    target = CATALOG / f"{name}.imageset"
    target.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target / source.name)
    write_json(
        target / "Contents.json",
        {
            "images": [{"filename": source.name, "idiom": "universal",
                        "scale": "1x" if scale_free else "2x"}],
            "info": {"author": "xcode", "version": 1},
            # Les icônes et captures sont des images, pas des symboles : elles
            # gardent leurs couleurs et ne se teintent pas.
            "properties": {"preserves-vector-representation": False},
        },
    )


def build_own_icon(tokens: dict) -> list[str]:
    """La vignette du portfolio dans l'onglet « Mes apps ».

    L'API sert cette application comme une app à lui, au même titre que
    KCalories, et l'onglet dessine une icône par slug. Celle-ci ne vient donc
    pas de `portfolio-web` comme les trente-trois autres : elle n'a pas de fiche
    App Store d'où la tirer.

    Elle est **générée**, à partir du même tracé que l'icône de l'application,
    pour une raison précise : c'est la même identité affichée deux fois dans le
    même téléphone — sur l'écran d'accueil et dans l'onglet. Un « A » redessiné à
    l'œil, ou un PNG committé une fois puis oublié, dériverait de l'accent le
    jour où les tokens changent, et personne ne le verrait.
    """
    target = CATALOG / f"{OWN_SLUG}.imageset"
    problems: list[str] = []

    if CHECK:
        if not (target / f"{OWN_SLUG}.png").exists():
            problems.append(f"icône « {OWN_SLUG} » manquante — lancer ./Scripts/assets.py")
        return problems

    target.mkdir(parents=True, exist_ok=True)
    draw_app_icon(tokens, size=OWN_ICON_SIDE).save(
        target / f"{OWN_SLUG}.png", format="PNG", optimize=True
    )
    write_json(
        target / "Contents.json",
        {
            "images": [{"filename": f"{OWN_SLUG}.png", "idiom": "universal", "scale": "1x"}],
            "info": {"author": "xcode", "version": 1},
            "properties": {"preserves-vector-representation": False},
        },
    )
    print(f"✓ icône « {OWN_SLUG} » générée depuis design/tokens.json")
    return problems


def build_imported() -> list[str]:
    problems: list[str] = []
    expected = {"icons": ".png", "shots": ".jpg"}

    for folder, suffix in expected.items():
        sources = sorted((WEB / folder).glob(f"*{suffix}")) if (WEB / folder).exists() else []

        if CHECK:
            existing = {p.name.removesuffix(".imageset") for p in CATALOG.glob("*.imageset")}
            missing = [p.stem for p in sources if p.stem not in existing] if sources else []
            if not sources:
                print(f"· {folder} : dépôt web absent, import non vérifié")
            elif missing:
                problems.append(f"{len(missing)} actif(s) de {folder} absent(s) : {', '.join(missing[:5])}…")
            else:
                print(f"✓ {folder} : {len(sources)} actifs présents dans le catalogue")
            continue

        if not sources:
            print(f"✖ {WEB / folder} introuvable — import impossible", file=sys.stderr)
            problems.append(f"{folder} introuvable")
            continue

        for source in sources:
            import_imageset(source.stem, source)
        print(f"✓ {folder} : {len(sources)} actifs importés")

    return problems


def main() -> int:
    tokens = json.loads(TOKENS.read_text(encoding="utf-8"))
    if not CHECK:
        CATALOG.mkdir(parents=True, exist_ok=True)
        write_json(CATALOG / "Contents.json", {"info": {"author": "xcode", "version": 1}})

    problems = build_app_icon(tokens) + build_own_icon(tokens) + build_imported()
    for problem in problems:
        print(f"✖ {problem}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
