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

### 0. Le source Swift est en anglais

Commentaires, types, fonctions, variables locales. **Sans exception.**

La raison est de lectorat : ce dépôt est ouvert par des gens qui ne lisent pas
forcément le français, et un raisonnement qu'ils ne peuvent pas lire ne sert à
rien. `docs/` et le contenu de l'application restent en français.

`./Scripts/check-language.sh` le refuse en CI.

### 1. Une couche = un package. Le manifeste **est** la frontière

Chaque couche a son `Package.swift`, donc ses propres dépendances. `Features` ne
déclare jamais `Networking` : dans un écran, `import Networking` ne donne pas une
remarque en revue, il donne **« no such module »**.

```
Core          rien            ← mécaniques : horloge, stockage, réseau-dispo, bus
Domain        rien            ← entités + ports. Zéro dépendance, et c'est le point
Networking    rien
DesignSystem  rien            ← le langage visuel. Des valeurs, rien qui dessine
CoreUI        DesignSystem + Lottie + Textual   ← les composants, et SEUL à les connaître
Data          Domain + Networking + Core        ← le seul qui voie les deux côtés
Presentation  Domain                            ← et SURTOUT pas SwiftUI
Features      Domain + Presentation + DesignSystem + CoreUI
Composition   tout                              ← le seul, et il n'a aucune logique
```


Trois invariants qu'aucun manifeste ne peut tenir : **le domaine ignore qu'une
interface existe**, **la présentation ne dessine pas** (SwiftUI vient du SDK), et
**`import Textual`, `import Lottie`, `import PDFKit` n'existent que dans
`CoreUI`**. C'est `./Scripts/check-layers.sh` qui les refuse.

⚠️ **`Core` est un tiroir fourre-tout en puissance** — tout le monde en dépend,
donc tout ce qu'on y met devient global. Le critère d'entrée est écrit dans son
manifeste : sert à **deux couches au moins**, ne sait **rien** du portfolio, et
pourrait être livré dans une autre application sans changer d'une ligne.

`ArchitectureTests` lit tous les manifestes et échoue si le graphe dérive.

⚠️ **`Data` n'est pas `Adapters`.** Un « adapter » est un *rôle* — `URLSessionHTTPClient`
en est un, `PortfolioStore` aussi. L'anneau *Interface Adapters* a deux moitiés :
les **gateways** (`Data`) et les **presenters** (`Presentation`). Ne pas refondre
les deux sous un seul nom : l'erreur a déjà été faite et corrigée le 2026-09-18.

⚠️ **Pas de préfixe `Amissan` sur les packages.** Le nom du package est celui du
module.

### 2. Aucune valeur de design écrite à la main

Couleurs, espacements, rayons, courbes descendent de `design/tokens.json` par
`Scripts/tokens.mjs`. Une valeur en dur dans une vue est une erreur, pas un
raccourci — et `./Scripts/tokens.mjs --check` la refuse en CI.

Après toute modification des tokens : `./Scripts/tokens.mjs`.

### 3. Aucun fait n'est écrit dans ce dépôt

ADR 0002. Chiffres, dates, phrases : tout vient de `portfolio-api`. Ce qui reste
ici, ce sont les **libellés d'interface** (`AppChrome`) et la **documentation
d'architecture** (`AppDossier`) — qui n'ont aucun sens sans l'application.

La graine embarquée (`Packages/Data/Sources/Data/Resources/seed-*.json`) est **générée** par
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
./Scripts/test.sh              # les 13 suites, sur simulateur
./Scripts/tokens.mjs --check   # le design descend bien des tokens
./Scripts/seed.sh --check      # la graine décrit encore ce que sert l'API
./Scripts/assets.py --check    # chaque actif attendu est présent
./Scripts/check-secrets.sh     # dépôt public
./Scripts/check-language.sh    # le source Swift est en anglais
./Scripts/check-layers.sh      # aucune couche ne voit ce qu'elle ne doit pas
./Scripts/check-naming.sh      # le nom dit le rôle
./Scripts/check-suites.sh      # aucune suite ne s'est évaporée
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
| Horloge, stockage, connectivité, bus d'événements | `Packages/Core/` |
| Entités et ports | `Packages/Domain/Sources/Domain/` |
| Transport HTTP | `Packages/Networking/` |
| DTO, correspondances, dépôts, sources | `Packages/Data/Sources/Data/` |
| Tokens, couleurs, typo, mouvement | `Packages/DesignSystem/` |
| Composants, et Lottie / Textual / PDFKit | `Packages/CoreUI/` |
| Phases, store, chrome, formatage, routes | `Packages/Presentation/` |
| Vues partagées, environnement, icônes | `Packages/Features/Sources/ViewKit/` |
| Annotations de coulisses | `Packages/Features/Sources/Backstage/` |
| Coquille d'écran, résolution de routes | `Packages/Features/Sources/Features/Kit/` |
| Un écran | `Packages/Features/Sources/Features/<Nom>/` |
| Le câblage | `Packages/Composition/` |
| Configuration du projet | `project.yml` |
| Générateurs et gardes | `Scripts/` |

**Le nom dit le rôle.** `*DTO`, `*Mapper`, `*Repository`, `*DataSource`,
`*Request`, `*Response`, `*Store`, `*Screen`, `*View`, `*Stub`, `*Spy`. Deux
exceptions : les **entités** n'ont pas de suffixe (le domaine parle le
vocabulaire du métier), et les **protocoles** suivent Swift — `-able`, `-ible`,
`-ing`. `./Scripts/check-naming.sh` le tient. Détail : `docs/refonte.md` §21.

**Aucun `import` de bibliothèque hors de `CoreUI`.** Un écran demande
`MarkdownText`, `LottieAnimation`, `PDFPreview`. Le jour où la bibliothèque
change, un fichier change.

**Un fichier par type.** Un type public porte le nom de son fichier. Les
exceptions sont étroites : un type imbriqué reste avec son parent, une extension
de conformité courte reste avec le type, un `#Preview` reste avec sa vue.

**`private` par défaut.** On ne monte d'un cran qu'avec une raison nommée.
`package` est le niveau qu'on oublie : un type partagé entre deux modules d'un
même package n'a aucune raison d'être visible depuis l'application. Dans
`Features`, la moitié de la surface est `package` — et `check-layers.sh` refuse
un type `public` que rien, dehors, ne nomme.

## Ce qui se discute avant d'être fait

- **Ajouter une dépendance.** La règle : *ce qui serait pire sans elle, pas ce
  qu'elle rend pratique.* Les arbitrages déjà rendus — Lottie oui, Alamofire
  non, Textual oui, SwiftData non — sont dans `AppDossier`, et l'application les
  affiche. En ajouter une, c'est devoir l'expliquer à l'écran.
- **Ajouter une cible.** Le graphe est la frontière : une cible de plus est une
  frontière de plus à justifier.
- **Toucher au contenu.** Les chiffres et les formulations sont des arbitrages
  rendus, consignés dans `.claude/rules/contenu-editorial.md` du workspace.
