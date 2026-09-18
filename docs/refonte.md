# La refonte — cahier des charges

> Rédigé le 2026-09-18, après la première version de l'application.
>
> **Ce document est la référence.** Tout ce qui suit a été demandé explicitement.
> Rien n'y est inventé, rien n'y est omis. Ce qui est fait se coche ; ce qui est
> écarté se dit, avec sa raison.

## Le constat, dans les mots de l'auteur

> « Je n'aime pas vraiment l'app. Elle est trop basique, elle ne fait pas du tout
> app iOS. **Elle fait web app.** »
>
> « Ça fait juste textes en gribouillis. »
>
> « Le "Open to opportunities" comme ça, c'est du web, c'est du IA generated. »
>
> « L'app sera évaluée donc je veux qu'elle soit nickel. Chaque petit détail
> compte. »

Le diagnostic est juste, et il est structurel : la première version a **transposé
la mise en page du site**. Des sections empilées, des cartes, du texte long, des
pastilles. C'est une page web rendue en SwiftUI.

Une application iOS ne se lit pas, elle **se manipule**. Elle a des gestes, des
profondeurs, des retours, des états. C'est ce qui manque, et ce n'est pas une
couche de vernis à ajouter : c'est la conception à reprendre.

---

## 1. Écrans et vues — la séparation

**Demandé :** *« Je veux que tu différencies les Screens de views ! Les vues
doivent être bêtes et ne faire que du rendu ! Chaque écran est un Screen et c'est
le Screen qui porte le viewModel ou Store, le routing etc. »*

| | Rôle | Connaît | Ne connaît pas |
|---|---|---|---|
| **Screen** | orchestre | le store, le routeur, les phases, les effets | comment on dessine |
| **View** | rend | ses paramètres, et rien d'autre | le store, le routeur, le réseau |

Une `View` ne prend **aucune** dépendance d'environnement métier : pas de
`@Environment(PortfolioStore.self)`, pas de `Router`. Elle reçoit des valeurs et
des fermetures. Conséquences recherchées :

- elle se prévisualise sans rien monter ;
- elle se teste par instantané sans simulateur ;
- un changement d'orchestration ne la touche pas.

**Garde :** un test d'architecture refuse qu'un fichier `*View.swift` mentionne
`Store`, `Router` ou `Repository`.

---

## 2. `ViewPhase` — quatre états, partout

**Demandé :** *« Chaque Screen doit avoir un phase loading, initial, loaded et
error ! »*

```swift
enum ViewPhase<Value> {
  case initial     // rien n'a encore été demandé
  case loading     // une demande est en vol, rien à montrer
  case loaded(Value)
  case failed(Error)
}
```

`initial` et `loading` sont **distincts** et ce n'est pas une subtilité : le
premier ne doit rien afficher du tout (l'écran vient d'apparaître), le second
doit montrer un squelette. Les confondre produit un clignotement à chaque
navigation.

La phase porte aussi le cas **« chargé mais en cours de rafraîchissement »** —
c'est ce qui permet d'afficher le contenu du cache *et* l'activité réseau sans
que l'un remplace l'autre.

Un composant unique — `PhaseView` — rend les quatre cas, avec les transitions
qui vont entre. Aucun écran ne réécrit ce `switch`.

---

## 3. Les réglages

**Demandé :** *« Un menu paramètres dans l'app qui me permet de changer la
langue, le thème (light dark system) ; pour la langue pareil, system fr ou en ;
avec fallback en `en` si la langue système n'est ni fr ni en. »*

| Réglage | Valeurs | Défaut |
|---|---|---|
| Thème | `système` · `clair` · `sombre` | système |
| Langue | `système` · `français` · `anglais` | système |

**La règle de repli change.** Aujourd'hui : français. Demandé : **anglais** quand
la langue système n'est ni français ni anglais. C'est le bon choix — un visiteur
germanophone lit l'anglais, pas le français.

Persisté localement (`UserDefaults` via un port `PreferencesStoring`, pas un
accès direct). Un changement de langue **recharge le contenu** dans la nouvelle
langue et met à jour le chrome — les deux dérivant déjà de la même valeur.

L'écran de réglages porte aussi : la version, l'empreinte du contenu affiché, sa
provenance, un bouton « vider le cache », et la bascule du mode coulisses.

---

## 4. Ce qui fait qu'une application est native

**Demandé :** *« Montre l'étendue de la beauté et l'aboutissement UI/UX que peut
avoir une app iOS ! »* · *« Rajoute des feedbacks visuels ! Retours haptiques,
toasters, alerts s'il le faut ! »*

### 4.1 Le mouvement

- transitions de navigation **`.navigationTransition(.zoom)`** entre une carte et
  son détail — le geste iOS 18+ qui fait qu'un élément « s'ouvre » ;
- `matchedGeometryEffect` pour les éléments qui persistent d'un état à l'autre ;
- `scrollTransition` : les éléments entrent avec une échelle et une opacité liées
  à leur position, pas à un minuteur ;
- `symbolEffect` sur les symboles SF — `.bounce` à la confirmation,
  `.pulse` pendant une attente ;
- `contentTransition(.numericText())` là où un nombre change ;
- **et `prefers-reduced-motion` supprime tout ça**, il ne l'atténue pas.

### 4.2 Le retour

| Situation | Retour |
|---|---|
| Action confirmée (CV téléchargé, lien copié) | `.sensoryFeedback(.success)` + bandeau |
| Bascule d'un réglage | `.sensoryFeedback(.selection)` |
| Échec récupérable | `.sensoryFeedback(.error)` + bandeau avec action |
| Action destructive | `.confirmationDialog` |
| Erreur bloquante | `.alert` |

Un **bandeau** (toast) maison, posé en `safeAreaInset`, qui ne masque rien et
disparaît seul. Jamais une `alert` pour une information — l'alerte est réservée
au choix critique.

### 4.3 Lottie, vraiment

**Demandé :** *« Je n'ai vu aucune belle anim Lottie ou quoi non plus ! »*

Constat juste : il y en a **une**, un trait de 34 points sous le nom. Ce n'est pas
une démonstration.

À produire : un état vide animé, un état d'erreur animé, une animation de
succès au téléchargement du CV, et une animation d'ouverture sur l'écran des
coulisses. Toutes écrites à la main depuis les tokens, comme la signature.

---

## 5. Le catalogue iOS à démontrer

**Demandé :** *« Montre les différents trucs d'une app iOS ! fullScreenCover,
covers, sheet, push, present… VStack, ZStack, GridStack et j'en passe ! »*

Chacun **là où il est justifié**, jamais pour faire nombre — et chacun annoté
dans les coulisses avec la raison de son emploi :

| Présentation | Où, et pourquoi |
|---|---|
| `push` | une étude de cas : on y entre, on en revient |
| `sheet` + `presentationDetents` | une explication de coulisses : on garde l'écran en vue |
| `fullScreenCover` | le CV en PDF : une lecture immersive |
| `popover` | une définition courte sur iPad |
| `confirmationDialog` | choisir la langue du CV avant de le partager |
| `alert` | seulement une erreur qui bloque |
| `contextMenu` | actions secondaires sur une carte d'application |
| `TipKit` | signaler le mode coulisses **une fois** |

| Disposition | Où |
|---|---|
| `ZStack` | l'accroche en couches — fond, contenu, dégradé |
| `LazyVGrid` | la grille des applications |
| `Grid` | un tableau de comparaison d'architectures, aligné en colonnes |
| `Layout` sur mesure | la rangée d'étiquettes qui passe à la ligne |
| `ViewThatFits` | l'accroche qui se réorganise en accessibilité extra-large |
| `ScrollView(.horizontal)` + `scrollTargetBehavior` | les captures, les chiffres |

---

## 6. L'accroche, à refaire

**Demandé :** *« Le "Open to opportunities" comme ça, c'est du web, c'est du IA
generated. »*

La pastille verte à point, les trois lignes à icônes, les deux boutons côte à
côte : c'est le vocabulaire d'une page d'accueil web.

À remplacer par une **ouverture d'application** : une carte d'identité qui occupe
le premier écran, avec la photo ou le monogramme, le nom, le métier, et **une
seule** action principale. La disponibilité se dit dans la barre de navigation ou
dans un `ToolbarItem`, pas dans une pastille flottante.

Le texte long de l'accroche part dans un écran « À propos » atteignable — le
premier écran donne l'échelle, pas le récit.

---

## 7. Le CV, accessible en trois secondes

**Demandé :** *« L'accès au téléchargement du CV doit être plus facile et
intuitif ! Là c'est galère de savoir. »*

- un `ToolbarItem` permanent, présent sur **tous** les écrans ;
- ouverture en `fullScreenCover`, avec la langue choisie par
  `confirmationDialog` quand les deux existent ;
- `ShareLink` et **enregistrement dans Fichiers** ;
- retour haptique et bandeau à la fin du téléchargement.

---

## 8. Les coulisses, étendues

**Demandé :** *« Toutes les explications que tu as mises en commentaire, on
devrait pouvoir les avoir dans l'app ? »* · *« Ces composants aussi ne sont pas
ouf pour du natif ! Tu pourras glisser des explications sur tout ça au clic. »*

⚠️ **Tension à arbitrer, et elle est réelle.** L'auteur demande *plus*
d'explications dans une application qu'il trouve déjà trop textuelle. Les deux
sont vrais. La réponse n'est pas de choisir, c'est la **révélation progressive** :

1. au repos, **rien** — l'application est une application ;
2. mode coulisses activé : des pastilles numérotées ;
3. au toucher : une phrase et le nom du composant ;
4. « en savoir plus » : l'explication entière, avec ce qui a été écarté.

Le texte long ne disparaît pas ; il cesse d'être la première chose qu'on voit.

À couvrir en annotations : chaque présentation, chaque disposition, chaque
animation, chaque décision de concurrence, chaque repli de compatibilité.

---

## 9. Les architectures des projets passés

**Demandé :** *« Précise les archis des différents projets sur lesquels j'ai
bossé ! MVC stiilt, MVC orange, MVP Instant ; puis MVVM et clean archi c'est bien
ça ? Instant tu peux toi-même vérifier les archis ! »*

**Vérifié dans les dépôts, le 2026-09-18** — et le souvenir était partiellement
inexact :

| Socle | Ce que montrent les fichiers | Lecture |
|---|---|---|
| **v1** | 304 `*ViewController`, **325 `*ViewModel`**, 124 `*Flow`, 14 `*Presenter` | **MVVM sur UIKit**, navigation par objets de flux. MVP ne couvre qu'une poignée de modules |
| **v2** | découpage `Features/<nom>/{Domain, Infrastructure, Presentation}`, 677 `UseCase`, 417 `Repository`, 558 `*Protocol`, 69 `*Store` en `ObservableObject` | **Clean Architecture** modularisée par fonctionnalité, SwiftUI |

Donc **MVVM/UIKit → Clean Architecture/SwiftUI**, et non « MVP puis MVVM ».
C'est plus fort à raconter, et c'est vérifiable.

🔴 **Ce qui ne sort pas :** aucun nom de module interne, de client, de
prestataire, ni de dépôt. On décrit des **motifs d'architecture**, jamais le code
d'un employeur.

Un écran compare **MVC · MVP · MVVM · Clean**, en `Grid` : ce que chacun sépare,
ce qu'il coûte, quand le choisir, et où il casse. En langage d'ingénieur qui les
a pratiqués — pas en article générique.

---

## 10. L'API : des routes pour l'application seule

**Demandé :** *« On peut avoir de nouveaux endpoints côté API qui ne servent que
l'app iOS car l'app iOS est censée être le portfolio le plus détaillé. »*

Oui. À concevoir :

- `/v1/architectures` — les motifs, leurs différences, les arbitrages ;
- `/v1/deep-dives` — les sujets creusés, en version longue ;
- `/v1/timeline` — le parcours avec le détail que le site abrège.

Ces routes restent **servies par la même source** : une seule vérité, des vues
différentes. Le site n'a aucune raison d'y toucher.

---

## 11. Abstractions et injection

**Demandé :** *« Je veux ÉNORMÉMENT d'abstractions et d'injections de
dépendances ! Les différentes couches ne doivent pas se connaître ! Un changement
UI ne doit pas perturber les mappings webservices. »*

L'objectif est **déjà tenu** sur le fond : les couches sont des cibles SPM, une
fonctionnalité ne compile pas si elle importe le réseau, et un test lit le
manifeste pour l'empêcher de dériver.

⚠️ **Une réserve, et je la pose franchement.** « Énormément d'abstractions » n'est
pas un but en soi. Un protocole qui n'a qu'une implémentation et qu'on ne
remplacera jamais coûte une indirection à chaque lecture, et un relecteur senior
le relève comme une sur-ingénierie — pas comme une qualité.

Ce qui sera fait :

- une **abstraction là où elle achète quelque chose** : remplaçabilité réelle,
  testabilité sans simulateur, ou frontière d'équipe ;
- un port pour tout ce qui touche le monde extérieur : réseau, disque,
  préférences, horloge, haptique, ouverture d'URL ;
- l'injection par **valeurs de composition**, pas par un conteneur : le graphe se
  lit en dix lignes, et le compilateur garantit qu'il est complet ;
- et — c'est ce qui vaut le plus — l'application **explique dans les coulisses
  là où elle a délibérément choisi de ne pas abstraire**. Savoir où s'arrêter se
  démontre mieux que des protocoles partout.

---

## 12. La structure des dossiers

**Demandé :** *« FeatureWork, FeatureJourney, etc. ? Faudrait peut-être un
dossier Feature ? »*

Oui. Les cibles gardent leur nom — c'est lui qui apparaît dans les imports — mais
leurs sources passent sous `Sources/Features/<Nom>/` via le `path:` du manifeste.

```
Sources/
  Domain/  Networking/  Persistence/  Data/
  DesignSystem/  Backstage/
  Features/
    Kit/  Profile/  Work/  Journey/  Resume/  Backstage/  Settings/
  AppComposition/
```

---

## 13. Accessibilité

**Demandé :** *« Faut aussi gérer l'accessibilité oui ! »*

- **Dynamic Type jusqu'à AX5** : chaque écran vérifié en capture, et
  `ViewThatFits` là où la mise en page doit se réorganiser ;
- **VoiceOver** : ordre de lecture, regroupements, étiquettes et indices — un
  chiffre et sa légende forment un élément ;
- **contraste** mesuré sur les deux thèmes, y compris sur le verre ;
- **mouvement réduit** supprime, n'atténue pas ;
- **cibles tactiles** à 44 points au moins, vérifiées ;
- un test qui parcourt les écrans en accessibilité extra-large et échoue sur un
  débordement.

---

## 14. Le rafraîchissement au retour

Trou relevé pendant la rédaction : l'application charge au lancement, mais **ne
se rafraîchit pas** quand elle revient au premier plan après plusieurs jours.

À corriger : relecture sur `scenePhase == .active` si l'instantané dépasse un
certain âge.

---

## 15. L'ordre d'exécution

1. **Fondations** — `ViewPhase`, séparation Screen/View, structure `Features/`,
   ports de préférences/haptique/horloge ;
2. **Réglages** — langue, thème, repli anglais, persistance ;
3. **Accroche** — la refaire en application, pas en page web ;
4. **Mouvement et retours** — transitions, haptique, bandeaux, Lottie ;
5. **Catalogue de présentations** — chacune là où elle est justifiée, annotée ;
6. **Coulisses étendues** — révélation progressive, comparatif d'architectures ;
7. **Routes d'API dédiées** — architectures, approfondissements, chronologie ;
8. **Accessibilité** — la passe complète, avec ses tests ;
9. **CI** — captures automatiques des écrans, dans les deux langues, les deux
   thèmes, iOS 18 et 26, iPhone et iPad.

---

## Ce qui reste hors périmètre, et pourquoi

- **fastlane / TestFlight** — écrit après la refonte : livrer une application
  qu'on va reprendre entièrement n'apporte rien ;
- **le paysage et l'écran partagé sur iPad** — à regarder, pas encore tenu pour
  acquis.
