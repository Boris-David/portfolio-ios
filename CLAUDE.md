# portfolio-ios — instructions de dépôt

> Ce fichier se charge à **chaque** session ouverte dans ce dépôt. Il ne contient
> que ce qui régit le dépôt **entier**. Ce qui ne concerne qu'une sous-surface —
> architecture, design system, coulisses, CI — vit dans `.claude/rules/` avec un
> `paths:`, et ne se charge que quand on touche aux fichiers concernés.
>
> Le workspace `portfolio` ajoute par-dessus ses règles racines (posture,
> périmètre, workflow git, contenu éditorial). Sur la qualité, **c'est toujours
> la barre la plus haute qui gagne.**

## Ce qu'est ce dépôt

L'application iOS d'Amissan Amoussou-G. Son CV **est** une application : elle
affiche son parcours, et elle explique comment elle est faite.

**L'application est elle-même la démonstration.** Un raccourci pris ici n'est pas
une dette technique privée : c'est une pièce à conviction contre son auteur. Le
lecteur visé ouvre le dépôt, pas seulement l'App Store.

## Les invariants — ce qui ne se négocie pas

### 1. Le graphe de modules est la frontière

Chaque couche est une **cible SPM**. `FeatureProfile` ne déclare pas
`Networking` : `import Networking` ne compile pas. Ce n'est pas une convention,
c'est une erreur de compilation.

`Domain` ne dépend de rien. Aucune fonctionnalité ne voit `Networking`,
`Persistence` ni `Data`. Aucune fonctionnalité n'en importe une autre.
`ArchitectureTests` lit le manifeste et échoue si le graphe dérive.

### 2. Aucune valeur de design écrite à la main

Couleurs, espacements, rayons, courbes descendent de `design/tokens.json` par
`Scripts/tokens.mjs`. Une valeur en dur dans une vue est une erreur, pas un
raccourci — et `./Scripts/tokens.mjs --check` la refuse en CI.

Après toute modification des tokens : `./Scripts/tokens.mjs`.

### 3. Aucun fait n'est écrit dans ce dépôt

ADR 0002. Chiffres, dates, phrases : tout vient de `portfolio-api`. Ce qui reste
ici, ce sont les **libellés d'interface** (`AppChrome`) et la **documentation
d'architecture** (`AppDossier`) — qui n'ont aucun sens sans l'application.

La graine embarquée (`Sources/Data/Resources/seed-*.json`) est **générée** par
`./Scripts/seed.sh`, jamais écrite à la main.

### 4. La langue affichée est celle du contenu, pas celle de l'appareil

Un catalogue de chaînes suit l'appareil. Le contenu vient de l'API. Les deux
peuvent donc différer — et le défaut s'est produit : des onglets français
au-dessus d'un texte anglais.

`\.contentLanguage` porte **une** langue, et `AppChrome` s'en dérive. Ne jamais
réintroduire un `Localizable.xcstrings` pour le chrome sans rouvrir cette
décision.

### 5. Un contenu incomplet arrête tout — il ne se replie jamais en silence

Un rôle d'application inconnu **lève**. Un champ manquant **lève**, en nommant
son chemin. La seule exception assumée est l'affichage hors ligne, qui **dit**
ce qu'il affiche et depuis quand.

### 6. Le projet Xcode n'est pas versionné

Il se génère depuis `project.yml` (`xcodegen generate`). Ne jamais committer
`Amissan.xcodeproj`.

## Avant d'annoncer que c'est fait

```bash
xcodegen generate
./Scripts/test.sh              # les 8 suites, sur simulateur
./Scripts/tokens.mjs --check   # le design descend bien des tokens
./Scripts/seed.sh --check      # la graine décrit encore ce que sert l'API
./Scripts/assets.py --check    # chaque actif attendu est présent
./Scripts/check-secrets.sh     # dépôt public
```

**Et on regarde l'écran.** Une application qui compile n'est pas une application
qui marche : trois défauts de cette base — le mode de compatibilité sans
`UILaunchScreen`, l'annotation qui effaçait ses voisines, le bouton principal
illisible sur iOS 18 — ne se voyaient qu'en capture d'écran.

```bash
xcrun simctl launch <appareil> dev.amissan.portfolio -backstage
xcrun simctl io <appareil> screenshot capture.png
```

## Où vont les choses

| Quoi | Où |
|---|---|
| Entités et ports | `Packages/AmissanKit/Sources/Domain/` |
| Transport, stockage | `Sources/Networking/`, `Sources/Persistence/` |
| DTO, correspondances, dépôts | `Sources/Data/` |
| Couleurs, typo, mouvement, composants | `Sources/DesignSystem/` |
| Annotations de coulisses | `Sources/Backstage/` |
| Un écran | `Sources/Feature*/` |
| Le câblage | `Sources/AppComposition/` |
| Configuration du projet | `project.yml` |
| Générateurs et gardes | `Scripts/` |

## Ce qui se discute avant d'être fait

- **Ajouter une dépendance.** La règle : *ce qui serait pire sans elle, pas ce
  qu'elle rend pratique.* Les arbitrages déjà rendus — Lottie oui, Alamofire
  non, Textual oui, SwiftData non — sont dans `AppDossier`, et l'application les
  affiche. En ajouter une, c'est devoir l'expliquer à l'écran.
- **Ajouter une cible.** Le graphe est la frontière : une cible de plus est une
  frontière de plus à justifier.
- **Toucher au contenu.** Les chiffres et les formulations sont des arbitrages
  rendus, consignés dans `.claude/rules/contenu-editorial.md` du workspace.
