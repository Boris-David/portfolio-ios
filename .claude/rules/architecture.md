---
paths:
  - "Packages/AmissanKit/Package.swift"
  - "Packages/AmissanKit/Sources/Domain/**"
  - "Packages/AmissanKit/Sources/Networking/**"
  - "Packages/AmissanKit/Sources/Persistence/**"
  - "Packages/AmissanKit/Sources/Data/**"
  - "Packages/AmissanKit/Sources/AppComposition/**"
---

# Architecture — les couches et ce qu'elles ignorent

> Chargée quand on touche au manifeste ou aux couches non visuelles.

## Le graphe, et pourquoi il est tenu par le compilateur

```
                   ┌──────────────────┐
                   │  AppComposition  │  ← le seul qui connaisse tout le monde
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

« Les vues ne connaissent pas le réseau » est une règle d'équipe, et les règles
d'équipe se contournent le vendredi soir. Ici c'est une **erreur de
compilation** : `Networking` n'est pas dans les dépendances de `FeatureProfile`.

Et le manifeste lui-même est sous test — `ArchitectureTests` refuse une arête
interdite, parce qu'on pourrait très bien *ajouter* la dépendance au manifeste et
le compilateur serait alors d'accord.

## Ce que chaque couche n'a pas le droit de savoir

| Couche | Ignore |
|---|---|
| `Domain` | tout. Pas de transport, pas de stockage, pas de SwiftUI, pas de sérialisation |
| `Networking` | ce qu'est un profil. Aucun de ses types ne nomme une entité |
| `Persistence` | à quoi servent les octets qu'il écrit |
| `DesignSystem` | le domaine. Il doit rester utilisable dans une autre application |
| `Feature*` | `Networking`, `Persistence`, `Data`, et leurs sœurs |

**Les DTO vivent dans `Data`, jamais dans `Domain`.** Une entité qui porte des
`CodingKeys` est une entité qui a laissé le réseau dicter sa forme.

## La concurrence

`PortfolioRepository` et `ResumeRepository` sont des **acteurs**, et ils
**mémorisent la tâche en cours**. Quatre écrans qui demandent le contenu en même
temps produisent **une** requête — c'est testé, et la mutation du test le prouve
(sans fusion : 3 requêtes au lieu d'une).

Un verrou aurait protégé l'état à condition qu'on pense à le prendre partout, et
un verrou tenu pendant une attente asynchrone est un blocage qui n'attend que son
heure. Avec un acteur, l'isolation est une **propriété du type**.

`URLSessionHTTPClient` est une `struct`, pas un acteur : elle ne porte aucun état
mutable, et un acteur y sérialiserait des requêtes qui ont intérêt à partir en
parallèle. **Un acteur n'est pas un label de sûreté qu'on colle par précaution.**

## La lecture en trois couches

1. **cache disque** — ce que la dernière session a rapporté ;
2. **graine embarquée** — générée à la construction depuis l'API ;
3. **réseau** — la vérité, quand il répond.

L'écran n'attend jamais le réseau. Il montre ce qu'il a, **dit** ce qu'il montre,
puis se met à jour.

⚠️ L'instantané réseau est émis **même quand l'empreinte n'a pas changé**. Ne pas
le faire était une optimisation qui rendait l'interface menteuse : le bandeau
continuait d'annoncer « contenu enregistré » alors que la source venait de
confirmer que ce contenu était courant.

## Le cache reçoit les octets, pas un ré-encodage

Ré-encoder ce qu'on a décodé perdrait tout champ qu'on ne lit pas encore, et une
version ultérieure de l'application le chercherait en vain dans un cache qu'elle
a elle-même appauvri.

## Les erreurs portent un lieu

`ContentUnavailable.malformed(path:reason:)`. Le `codingPath` de `DecodingError`
donne ce chemin gratuitement — un « contenu invalide » sans lieu n'aide personne,
et l'application l'affiche tel quel : quelqu'un qui regarde ce portfolio a tout
intérêt à voir le diagnostic réel.
