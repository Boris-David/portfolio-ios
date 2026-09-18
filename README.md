# Amissan — l'application iOS

Le portfolio d'Amissan Amoussou-G., en natif. Son CV **est** une application —
et elle explique comment elle est faite.

[amissan.dev](https://amissan.dev) · [l'API](https://github.com/Boris-David/portfolio-api)

## Ce qu'elle démontre

**Les décisions de conception, annotées à l'écran et révélées par paliers.** Au
repos, rien : c'est une application. Annotations activées, chaque composant
reçoit une pastille ; au toucher, son nom et une phrase ; « en savoir plus »,
l'explication entière — ce qui a été **écarté** et pourquoi, quand l'employer, et
le piège qu'il réserve. C'est la structure d'un ADR, à l'échelle du composant.

**Une frontière tenue par le résolveur.** Chaque couche est un **package** SPM
avec son propre manifeste. `Features/Package.swift` ne nomme jamais
`Networking` : dans un écran, `import Networking` ne donne pas une remarque en
revue, il donne « no such module ». Et le graphe lui-même est sous test, parce
qu'on pourrait ajouter la dépendance au manifeste.

**Trois invariants qu'aucun manifeste ne peut tenir**, et une garde qui les
refuse : le domaine ignore qu'une interface existe, la présentation ne dessine
pas, et `Textual`, `Lottie`, `PDFKit` ne s'importent que dans `CoreUI`.

**Le texte n'est pas dans le code, et la langue n'est pas celle de l'appareil.**
Un écran nomme une clé typée ; le mot vit dans un `.xcstrings` qu'on édite sans
ouvrir Xcode. Et il est résolu sur la langue du **contenu servi** — parce que la
source peut ne pas avoir celle du téléphone, et que des onglets français au-dessus
d'un texte anglais, c'est arrivé au premier lancement.

**Liquid Glass sur iOS 26, iOS 18 sans compromis.** Une seule base de code.
L'intention est nommée, le rendu décidé en un endroit, et la CI **lance
réellement** l'application sur un runtime iOS 18.

**Un design partagé avec le site.** Couleurs, espacements et courbes de mouvement
sont **générés** depuis le même `design/tokens.json` que le CSS. Pas « à peu près
la même palette » : la même valeur hexadécimale.

## Le graphe

```
Core          rien            mécaniques : horloge, stockage, connectivité, bus
Domain        rien            entités + ports
Networking    rien            HTTP
DesignSystem  rien            le langage visuel — des valeurs, rien qui dessine
Localization  rien            un catalogue, lu dans une langue NOMMÉE — jamais celle de l'appareil
CoreUI        DesignSystem    les composants, et SEUL à connaître Lottie/Textual/PDFKit
Data          Domain + Networking + Core        le seul qui voie les deux côtés
Presentation  Domain                            ni SwiftUI ni catalogue : des valeurs
                                                et des clés, jamais des phrases
Features      Domain + Presentation + DesignSystem + CoreUI + Localization
Composition   tout                              le seul, et il n'a aucune logique
```

## Démarrer

```bash
./Scripts/bootstrap.sh --clean --open
```

Le `.xcodeproj` est **généré** et non versionné : il est donc périmé après
n'importe quel `git checkout`. `bootstrap.sh` le régénère, restaure le verrou de
versions, efface le graphe de packages que Xcode garde en cache, et résout.

`--clean` efface en plus le graphe de packages que Xcode garde en cache. C'est
le drapeau qui répare l'état où trois packages s'affichent en **dossiers bleus**
et où `import Composition` répond « no such module » — pendant que la ligne de
commande compile le même projet sans broncher. Le script ferme Xcode lui-même et
le rouvre : il tient le graphe, et sans ça il continuerait à servir l'ancien.

Prérequis : Xcode 26 (SDK iOS 26), XcodeGen, Node 22, Python 3 avec Pillow.

## Vérifier

```bash
./Scripts/test.sh              # 13 suites, 161 tests, sur simulateur
./Scripts/tokens.mjs --check   # le design descend bien des tokens
./Scripts/seed.sh --check      # la graine décrit encore ce que sert l'API
./Scripts/assets.py --check    # chaque actif attendu est présent
./Scripts/check-secrets.sh     # dépôt public
./Scripts/check-language.sh    # le source Swift est en anglais
./Scripts/check-layers.sh      # aucune couche ne voit ce qu'elle ne doit pas
./Scripts/check-naming.sh      # le nom dit le rôle
./Scripts/check-suites.sh      # aucune suite ne s'est évaporée
./Scripts/check-strings.sh     # chaque clé a sa traduction, chaque traduction sa clé
./Scripts/screens.sh           # 21 captures : 2 thèmes, la plus grande taille
                               # d'accessibilité, et les écrans poussés
```

**Et on regarde l'écran.** Huit défauts de cette base ne se voyaient qu'en
capture, dont un titre tronqué qu'aucune exécution précédente n'avait montré
parce que la matrice capturait au mauvais calibre — et le disait quand même en
vert.

## Ce qui n'est écrit nulle part ici

Aucun fait. Chiffres, dates, phrases : tout vient de l'API. Ce qui reste dans ce
dépôt, ce sont les **libellés d'interface** et la **documentation d'ingénierie**
(`EngineeringRecord`, `<Feature>Decisions`) — qui n'ont aucun sens sans
l'application.

Et aucune de ces chaînes ne vit dans une vue : un écran nomme une **clé typée**,
le mot vit dans un `.xcstrings` qu'on édite sans ouvrir Xcode, et
`check-strings.sh` refuse le contraire — comme il refuse une clé morte, une
langue absente d'un seul catalogue, ou une vue qui lirait la langue.
