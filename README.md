# Amissan — l'application iOS

Le portfolio d'Amissan Amoussou-G., en natif. Son CV **est** une application —
et elle explique comment elle est faite.

[amissan.dev](https://amissan.dev) · [l'API](https://github.com/Boris-David/portfolio-api)

## Ce qu'elle démontre

**Un mode « coulisses ».** Chaque écran s'annote : quel composant SwiftUI est
employé, pourquoi celui-là, **ce qui a été écarté et pourquoi**, quand l'employer
en général, et le piège qu'il réserve. Un onglet entier détaille l'architecture,
les défis rencontrés, et les chaînes de bout en bout.

**Une frontière tenue par le compilateur.** Chaque couche est une cible SPM.
`import Networking` depuis une vue **ne compile pas** — et le graphe lui-même est
sous test, parce qu'on pourrait ajouter la dépendance au manifeste.

**Liquid Glass sur iOS 26, iOS 18 sans compromis.** Une seule base de code.
L'intention est nommée, le rendu décidé en un endroit, et la CI **lance
réellement** l'application sur un runtime iOS 18.

**Un design partagé avec le site.** Couleurs, espacements et courbes de mouvement
sont **générés** depuis le même `design/tokens.json` que le CSS. Pas « à peu près
la même palette » : la même valeur hexadécimale.

## Démarrer

```bash
xcodegen generate        # le projet n'est pas versionné, il se génère
open Amissan.xcodeproj
```

Prérequis : Xcode 26 (SDK iOS 26), XcodeGen, Node 22, Python 3 avec Pillow.

## Vérifier

```bash
./Scripts/test.sh              # 8 suites, 60 tests, sur simulateur
./Scripts/tokens.mjs --check   # le design descend bien des tokens
./Scripts/seed.sh --check      # la graine décrit encore ce que sert l'API
./Scripts/assets.py --check    # chaque actif attendu est présent
./Scripts/check-secrets.sh     # dépôt public
```

Et **regarder l'écran** — trois défauts de cette base ne se voyaient qu'en
capture :

```bash
xcrun simctl launch <appareil> dev.amissan.portfolio -backstage
```

## Les modules

```
                   ┌──────────────────┐
                   │  AppComposition  │  le seul qui connaisse tout le monde
                   └────────┬─────────┘
          ┌─────────────────┼──────────────────┐
          ▼                 ▼                  ▼
     Feature*            Data              Backstage
          │            ┌───┴────┐              │
          ▼            ▼        ▼              ▼
     FeatureKit   Networking Persistence  DesignSystem
          │                                    │
          └──────────► Domain ◄────────────────┘
```

`Domain` ne dépend de rien. Aucune fonctionnalité ne voit le réseau, le stockage
ni les dépôts. `Data` est le seul adaptateur.

## Les dépendances, et pourquoi

La règle : *une dépendance se justifie par ce qui serait pire sans elle, pas par
ce qu'elle rend pratique.*

| | | |
|---|---|---|
| **Lottie** | adoptée | personne ne réécrit un interpréteur d'animations After Effects |
| **Textual** | adoptée | `AttributedString(markdown:)` ignore listes et blocs de code |
| **Alamofire** | écartée | `URLSession` fait déjà tout ce dont l'application se sert |
| **SwiftData** | écartée | ni relation, ni requête, ni migration — une charge par langue |

Les deux refus sont expliqués **dans l'application**, à l'écran.
