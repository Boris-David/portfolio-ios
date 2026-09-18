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

## 0. La langue du code — non négociable

**Portée élargie le 2026-09-18 :** *« Why en français ? T'as oublié qu'ils
doivent être en anglais les comments et tout ? »* — la règle ne vise pas que le
Swift. **Tout commentaire de code, quel que soit le fichier**, est en anglais :
`project.yml`, les scripts shell, les `$comment` des JSON, les workflows.

Et **partout** : `portfolio-web` et `portfolio-api` aussi. Décidé le 2026-09-18.

Restent en français : `docs/`, les messages de commit, et le contenu de
l'application.

**Demandé, le 2026-09-18 :** *« Stop les commentaires de code et les noms de
classes, struct etc. en français. Tout ça doit être in English. Et c'est non
négociable. »*

**Tout le source Swift est en anglais** : commentaires, noms de types, de
fonctions, de variables locales. Sans exception.

La raison n'est pas stylistique, elle est de lectorat : ce dépôt est ouvert par
des recruteurs et des ingénieurs qui ne lisent pas forcément le français. Un
raisonnement écrit dans une langue qu'une moitié de l'audience ne lit pas gâche
exactement ce pour quoi il a été écrit.

Ce qui reste en français : **`docs/`**, qui s'adresse à l'auteur, et le
**contenu de l'application**, qui est bilingue par construction.

Tenu par `Scripts/check-language.sh`, exécuté en CI. La détection est une liste
de mots, pas une détection d'accents — « résumé » est un mot anglais valable et
ne doit pas déclencher la garde.

⚠️ **Portée à trancher** : `portfolio-web` et `portfolio-api` ont eux aussi leurs
commentaires en français. La règle devrait logiquement s'y appliquer, mais c'est
une passe mécanique sur du code qui n'est pas en cours de reprise. À décider.

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
study Feature ? »*

Oui. Les cibles gardent leur nom — c'est lui qui apparaît dans les imports — mais
leurs sources passent sous `Sources/Features/<Nom>/` via le `path:` du manifeste.

```
Sources/
  Domain/  Networking/  Persistence/  Data/
  DesignSystem/  Decisions/
  Features/
    Kit/  Profile/  Work/  Journey/  Resume/  Decisions/  Settings/
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

## 14. La politique de fraîcheur — corrigée

**Demandé, le 2026-09-18 :** *« Ce n'est même pas une histoire de quelques jours.
L'app utilise ce qu'elle a en local lorsqu'on part en timeout ou que le user n'a
pas de connexion internet. Au-delà de ça, il fait ses appels réseaux. Si on veut,
on peut mettre un mécanisme de cache sur certains appels. »*

Ça **corrige** ce que la première version fait. Elle sert le cache d'abord, puis
le réseau — deux instantanés à chaque ouverture. La politique demandée est
l'inverse, et elle est plus honnête : *ce qu'on affiche est ce que la source dit,
maintenant.*

```swift
enum FreshnessPolicy {
  /// Le réseau d'abord ; le local **seulement** s'il échoue. Le défaut.
  case networkFirst
  /// Le local d'abord s'il existe et n'a pas dépassé son âge, puis le réseau.
  /// Réservé aux appels dont le contenu ne bouge quasiment jamais.
  case cacheFirst(maxAge: Duration)
}
```

- **`networkFirst` partout par défaut.** Un appel part, la phase est `loading`,
  et l'écran montre un squelette. Sur délai dépassé ou absence de réseau, on
  bascule sur le local **en le disant** ;
- **`cacheFirst` à la demande**, appel par appel, quand le contenu ne bouge pas —
  le catalogue d'applications, par exemple. C'est le « mécanisme de cache sur
  certains appels » demandé, rendu explicite plutôt que subi ;
- **le repli garde ses trois couches** : cache disque, puis graine embarquée. Il
  ne sert plus à afficher vite, il sert à afficher **quand même**.

Et le trou relevé en rédigeant disparaît avec : l'application rappelle la source
à chaque retour au premier plan (`scenePhase == .active`), puisque le réseau est
désormais le chemin normal et non l'exception.

---

## 16. Un fichier par type

**Demandé :** *« Ici pareil, un fichier par DTO ! Au fait généralement, un fichier
par classe, struct, objet, protocol etc. »*

Un type public = un fichier portant son nom. `PortfolioDTO.swift` porte quinze
types ; il en portera un.

Les exceptions, et elles sont étroites :

- un type **imbriqué** reste avec son parent (`CaseStudy.Chapter` vit dans
  `CaseStudy.swift`) — le sortir couperait ce qui n'a pas de sens séparé ;
- une **extension de conformité** courte (`extension X: Equatable`) reste avec le
  type ;
- les **aperçus** (`#Preview`) restent avec la vue qu'ils montrent.

Bénéfice réel, au-delà du rangement : un fichier par type donne un historique git
par type. « Qui a changé ce DTO et pourquoi » devient une question à laquelle
`git log` répond.

---

## 17. La visibilité — `private` par défaut

**Demandé :** *« Fais également très attention aux visibilités ! C'est private par
défaut ! Pour être public faut vraiment qu'il y ait une raison ! Et quelque chose
de public d'une couche ne doit pas être visible sur une autre couche qui n'y a
pas accès. »*

La règle, du plus fermé au plus ouvert, et on ne monte d'un cran qu'avec une
raison nommée :

| Niveau | Quand |
|---|---|
| `private` | le défaut. Tout commence ici |
| `fileprivate` | un type auxiliaire partagé dans le même fichier |
| `internal` (implicite) | employé ailleurs dans **le même module** |
| `package` | employé par un autre module **du même package** — et par personne d'autre |
| `public` | franchit une frontière de package. Se justifie |
| `open` | jamais. Rien ici n'est conçu pour être sous-classé |

⚠️ **`package` est le niveau qu'on oublie**, et c'est précisément celui qui
manquait : un type utilisé par deux modules d'`AmissanKit` n'a aucune raison
d'être visible depuis l'application. Le passer `public` l'expose à tout le monde
pour satisfaire un voisin.

**Garde — et pas celle qui était prévue.** L'idée initiale était *« un test qui
compte les déclarations `public` par module et échoue au-delà d'un seuil »*.
Un seuil ne mesure rien : il se relève le jour où il gêne, et il ne dit jamais
*quelle* déclaration est de trop.

La règle retenue est falsifiable : **`public` veut dire « franchit une frontière
de package »**. Donc tout type `public` de `Features` doit être nommé quelque
part en dehors de `Features`. Si personne dehors ne le nomme, il est `package`.
`Scripts/check-layers.sh` le vérifie, et la mutation le confirme.

⚠️ La garde est **limitée à `Features`**, volontairement. Ailleurs elle crierait
au loup : `HTTPResponse` n'apparaît jamais par son nom dans `Data`, parce qu'il
arrive par inférence depuis `HTTPClient.send`. Une garde à faux positifs est une
garde qu'on apprend à sauter.

**Résultat mesuré :** dans `Features`, 15 déclarations `public` et 15 `package`
— la moitié de la surface a cessé d'être visible depuis l'application.

**Trois trouvailles de la passe :**

- `EmptySeed` était un **double de test** compilé dans l'application. Il est
  descendu dans la cible de test ;
- `InMemoryPreferences` n'avait aucun consommateur, nulle part. Supprimé ; il
  reviendra avec l'écran de réglages, dans le package qui en aura besoin ;
- `UserDefaultsPreferences` n'est encore branché à rien — il attend l'écran de
  réglages. Il a désormais ses tests, parce que son format de stockage est un
  **choix** (une chaîne plate relisible à la main, pas un blob encodé) et que ce
  choix a un mode de panne silencieux : rien ne casse, l'application s'ouvre
  simplement dans la mauvaise langue.

---

## 18. Chaque couche est un package — **fait**

**Demandé :** *« Je veux aussi que chaque couche puisse avoir des dépendances !
Ce qui fera qu'on pourra bloquer par dépendances le fait que certaines couches se
connaissent ou non. »*

C'est le prolongement de ce qui avait été fait pour le design system, et c'est
plus fort qu'une cible :

- une **cible** d'un même package voit les types `public` de ses sœurs dès qu'on
  ajoute la dépendance au manifeste — une ligne, et la frontière tombe ;
- un **package** a son propre manifeste et ne peut pas atteindre ce qu'il ne
  déclare pas. `Features/Package.swift` ne nomme jamais `Networking` : dans un
  écran, `import Networking` ne donne pas une remarque en revue, il donne
  « no such module ».

### Le découpage retenu

| Package | Ce qu'il contient | Ce qu'il déclare |
|---|---|---|
| `Domain` | entités, ports | **rien** |
| `Networking` | HTTP | rien |
| `Persistence` | octets sur disque | rien |
| `DesignSystem` | couleur, typo, mouvement | Lottie |
| `Data` | DTO, correspondances, dépôts, sources | Domain + les deux techniques |
| `Presentation` | phases, store, chrome, formatage, routes | Domain |
| `Features` | `ViewKit` → `Decisions` → `FeatureKit` → les écrans | Domain, Presentation, DesignSystem, Textual |
| `Composition` | le câblage | tout — et c'est le seul |

⚠️ **Pas de préfixe `Amissan`** : *« on sait qu'on est dans Amissan, donc pas
besoin de re-préfixer partout »*. Le nom du package est celui du module.

### Ce que le découpage rend possible

`package` — le niveau de visibilité qu'on oublie — **veut enfin dire quelque
chose**. Dans `Features`, un type partagé entre `ViewKit` et `FeatureKit` se
déclare `package` : les écrans le voient, l'application non. Avec un package par
cible, il aurait fallu le passer `public`, donc l'exposer à tout le monde pour
satisfaire un voisin.

---

## 18 bis. `Data` n'est pas `Adapters` — le renommage était une faute

**Relevé par l'auteur le 2026-09-18 :** *« Tu as renommé data en adapters ? Non,
on y est pas ! Pour moi ce sont deux choses différentes. […] Pour moi la couche
adapter c'est ce qui prépare les données pour la partie UI ; la couche data,
c'est autre chose. »*

Il a raison, et la correction a produit une couche de plus.

**« Adapter » est un rôle, pas un étage.** Tout ce qui convertit entre la forme
de l'application et celle d'une technologie en est un — `URLSessionHTTPClient`
en est un, et il vit dans `Networking` ; `PortfolioStore` en est un aussi, de
l'autre côté. Appeler `Adapters` le seul étage des dépôts revendiquait un rôle
qu'il ne détient pas seul.

**Dans le vocabulaire canonique**, l'anneau *Interface Adapters* de la Clean
Architecture contient **deux moitiés** qui n'ont rien à faire ensemble :

| Moitié | Ce qu'elle fait | Ici |
|---|---|---|
| **Gateways** | obtenir et écrire la donnée | `Data` |
| **Presenters** | préparer la donnée pour l'écran | `Presentation` |

L'intuition de l'auteur — « l'adapter, c'est ce qui prépare pour l'UI » —
désigne exactement la seconde. Elle **existait**, éparpillée dans `FeatureKit`,
mêlée à des vues SwiftUI, et **sans nom**. Ce qui n'a pas de nom ne peut pas
être dépendu volontairement, ni défendu en revue.

### `Presentation` — ce qui en sort et pourquoi

`ViewPhase`, `PhaseFailure`, `PortfolioStore`, `AppChrome`, `DateStyle`,
`Route`, `Sheet`, `AppSection`, `Router`.

**L'invariant : rien n'y importe SwiftUI.** C'est le test décisif d'une couche de
présentation — si ça dessine, c'est une vue ; si ça décide quoi dessiner, c'est
ici. Conséquence directe : tout s'y teste **sans simulateur et sans rendu**.

SwiftUI venant du SDK, aucun manifeste ne peut l'interdire : c'est
`Scripts/check-layers.sh` qui le refuse, et il est mutation-testé.

### `Icon` — le prix de l'invariant, et ce qu'il rapporte

Un `PhaseFailure` portant `"wifi.slash"` échoue au test ci-dessus : c'est une
instruction à un moteur de rendu précis. Il porte donc un **sens** — `.offline` —
et `ViewKit` décide du glyphe. Trois gains :

- la présentation se teste sans rendu : affirmer `.offline` est exact, affirmer
  `"wifi.slash"` teste une orthographe ;
- le jeu d'icônes change dans **un** fichier ;
- **un symbole SF mal orthographié n'affiche rien, en silence.** Un cas
  d'énumération ne peut pas être mal orthographié — et `IconTests` vérifie que
  chacun existe réellement (`UIImage(systemName:)` rend `nil` sinon).

### Le défaut que l'extraction a mis au jour

Deux traductions **divergentes** de la même erreur coexistaient :
`PortfolioStore` rendait `.nothingAvailable` avec une icône de bac vide, et une
seconde copie du même `switch` — écrite dans une vue — avec un symbole de wifi
barré. La même panne avait deux visages selon l'écran où l'on se trouvait.

Aucune des deux n'était fausse isolément, ce qui est précisément pourquoi
personne ne l'avait vu. **Une logique de présentation dupliquée ne se signale pas
en cassant : elle se signale en dérivant.** Il n'en reste qu'une,
`PhaseFailure.init(_:chrome:)`.

---

## 19. `AppRoot` viole le SRP

**Demandé :** *« Il y a trop de choses différentes dans `AppRoot.swift` ! C'est
clairement un antipattern ! SRP ! »*

Constat juste. Le fichier porte aujourd'hui : la `TabView`, la résolution des
routes, la résolution des feuilles, la feuille de contact, l'accessoire de barre,
la lecture de l'argument de lancement, et le câblage de l'environnement. Sept
responsabilités dans un fichier appelé « racine ».

Découpage :

| Fichier | Responsabilité unique |
|---|---|
| `AppRoot` | assembler la scène — et **rien** d'autre |
| `AppTabs` | la `TabView` et ses onglets |
| `RouteResolver` | route → écran |
| `SheetResolver` | feuille → écran |
| `ContactSheet` | son propre écran, dans sa fonctionnalité |
| `BackstageAccessory` | l'accessoire de barre |
| `LaunchArguments` | lire `-tab` et `-decision` |
| `AppEnvironment` | construire le graphe de dépendances |

---

## 20. Où on en est

*Tenu à jour à chaque étape, pour qu'une reprise ne reparte pas de zéro.*

**Fait :**

- [x] cahier des charges (ce document)
- [x] politique de fraîcheur : réseau d'abord, `cacheFirst(maxAge:)` par appel ;
      une charge mal formée n'est pas rattrapée par le cache ; le cache est écrit
      à **chaque** appel réussi
- [x] `ViewPhase` (4 états) + `PhaseView` + `FailureView`
- [x] `Sources/Features/` par le `path:` du manifeste
- [x] préférences dans le domaine (apparence, langue, coulisses), repli **anglais**
- [x] design system en package séparé
- [x] tokens en **deux couches** : hub partagé + `tokens.ios.json` spécifique,
      assemblés à la génération ; recouvrement refusé
- [x] zéro nombre magique (17 remplacés par des tokens)
- [x] **une couche = un package** (§18) — huit packages, sans préfixe `Amissan`
- [x] **`Data` rétabli**, et `Presentation` extraite (§18 bis) — les deux moitiés
      de l'anneau *Interface Adapters* cessent d'être confondues
- [x] `Scripts/check-layers.sh` — le domaine ignore SwiftUI, la présentation ne
      dessine pas ; mutation-testé
- [x] `ExistentialAny` activé partout — chaque existentiel se lit `any`
- [x] `AppRoot` découpé en sept types (§19)
- [x] **un fichier par type** (§16) — 151 fichiers Swift
- [x] **tout le Swift en anglais** (151 fichiers), CI comprise
- [x] `MalformedReason` — le diagnostic cesse d'être une phrase française
      fabriquée trois couches sous l'écran
- [x] `Icon` — un sens, pas un nom de glyphe ; `IconTests` vérifie que chacun existe
- [x] `Package.resolved` versionné — une construction propre ne résout plus au
      plus récent
- [x] garde de langue corrigée : elle prenait du **contenu** français pour des
      commentaires (toute ligne commençant par `**gras**`)

- [x] **`Core`** — horloge, stockage clé-valeur, connectivité, bus d'événements
      (§22). `Persistence` absorbé : deux abstractions du stockage, c'était la
      duplication à éviter
- [x] **`CoreUI`** — les composants, et le **seul** package qui nomme Lottie,
      Textual et PDFKit. `import Textual` ailleurs répond « no such module »
- [x] `DesignSystem` redevient le **langage visuel** : des valeurs, rien qui
      dessine — donc consommable hors SwiftUI
- [x] **les suffixes** (§21) — `check-naming.sh`, mutation-testé quatre fois
- [x] deux bugs trouvés par les mutations : `check-layers.sh` déclarait son
      verdict **entre** ses deux gardes, donc la seconde était effacée ; et des
      backticks dans une chaîne à guillemets doubles
- [x] `ConnectivityMonitor` **branché** sur la politique de fraîcheur : « hors
      ligne » se déduisait d'un échec après quinze secondes, alors que le système
      le savait avant que la requête ne parte. `.unknown` ne court-circuite rien
      — ne pas savoir n'est pas une raison de renoncer

- [x] **§3 l'écran de réglages** — langue, apparence, coulisses, réinitialisation
- [x] **l'injection segmentée par écran** (§11) — chaque écran déclare son
      protocole de dépendances, la racine prouve qu'elle sait le satisfaire.
      Interface Segregation, vérifiée par le compilateur, sans conteneur
- [x] **§6 l'accroche refaite** — monogramme, nom, signature, métier, **une**
      action ; la présentation longue part dans « À propos »
- [x] **§7 le CV en trois secondes** — `ToolbarItem` permanent sur tous les
      écrans, ouverture en `fullScreenCover`
- [x] **§8 les coulisses par paliers** — au repos rien, puis des pastilles, puis
      une phrase, puis tout. Le palier de feuille **est** la révélation
- [x] **§14 le rafraîchissement au retour** — premier plan et retour en ligne,
      la première activation exclue, une seule requête par transition
- [x] haptique (`sensoryFeedback` lié à une **valeur qui change**, jamais à un
      tap), bandeaux, `confirmationDialog`
- [x] `Scripts/screens.sh` — dix-huit captures, deux thèmes, `accessibility5`
- [x] garde de langue : elle ne voyait que les fichiers **suivis**, donc un
      fichier neuf passait au vert

- [x] **§4.3 les animations Lottie** — état vide, injoignable, CV téléchargé,
      écrites à la main depuis les tokens ; et elles **suivent le thème**, ce que
      la signature ne faisait pas
- [x] **§9 le comparatif d'architectures** — MVC · MVP · MVVM · Clean en `Grid`,
      et trois bases de code avec leurs comptes relevés
- [x] **§10 les routes iOS** côté API — `/v1/architectures`, `/v1/deep-dives`,
      `/v1/timeline`, avec deux gardes éditoriales falsifiées
- [x] **§5 le `popover`** — la provenance du contenu, rattachée au bandeau
- [x] **api en anglais** (56 fichiers)
- [x] un drapeau `-route` : la matrice atteignait les racines et les couvertures,
      jamais un écran **poussé**
- [x] **§23 le texte quitte le code** — 314 entrées dans des catalogues
      `.xcstrings`, résolus sur la langue du contenu ; `Bilingual` supprimé
- [x] **le vocabulaire** — « coulisses » et « chrome » retirés, `DesignDecision`
      et `EngineeringRecord` à la place, audit de nommage passé sur tout le dépôt
- [x] **l'API déployée** — `architectures` et `deepDives` sont en production,
      `seed.sh --check` est vert

- [x] **convertir web en anglais** (76 fichiers) — et, au passage, Tailwind
      retiré : 87 sélecteurs employés, 87 définis par le CSS maison, 0 utilitaire
      Tailwind ; rendu vérifié identique au pixel sur les deux langues

- [x] **§13 la passe d'accessibilité**, revue capture par capture à la plus
      grande taille — l'accroche du profil était tronquée (« Ingénieur iOS s… »),
      six textes servis par l'API pouvaient l'être, et le tableau comparatif
      cachait sa barre de défilement

**À faire :**
- [ ] fastlane / TestFlight
- [ ] l'écran partagé sur iPad

### ⚠️ Un ordre de livraison, pas un bug

`architectures` n'est pas déployé. Le DTO iOS le rend **non optionnel**, donc
l'application ne décode pas la charge de production : elle affiche « contenu
illisible » en nommant `data.architectures`, et le cache ne la rattrape pas.

C'est l'invariant n° 5 qui fonctionne, pas une régression. La conséquence est une
**contrainte d'ordre** : l'API part d'abord, l'application ensuite.
`seed.sh --check` échouera en CI jusque-là, et une garde qui tairait ça serait
pire qu'une garde rouge.

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

---

## 21. Les suffixes — le nom dit le rôle

**Demandé :** *« Tout ce qui est network request doit avoir le suffixe `Request`,
pareil pour les responses, pour les adapter `Adapter`, pour les screens `Screen`,
etc. Tu pourras l'adapter à nos couches réelles. »*

La règle, en une phrase : **le suffixe nomme le rôle dans l'architecture, jamais
la sorte Swift.** `PortfolioEntity` ou `LanguageEnum` ajoutent un mot qui ne dit
rien — tout type est un type. `PortfolioDTO` dit à quelle couche il appartient et
ce qu'il fait.

| Couche | Rôle | Suffixe | Exemple |
|---|---|---|---|
| `Domain` | entité | **aucun** | `Portfolio`, `CaseStudy`, `Experience` |
| `Domain` | port | **aucun** — voir l'exception | `PortfolioReading` |
| `Networking` | requête | `Request` | `HTTPRequest` |
| `Networking` | réponse | `Response` | `HTTPResponse` |
| `Networking` | transport | `Client` | `URLSessionHTTPClient` |
| `Data` | objet de transfert | `DTO` | `PortfolioDTO` |
| `Data` | traduction DTO → entité | `Mapper` | `PortfolioMapper` |
| `Data` | implémentation d'un port | `Repository` | `PortfolioRepository` |
| `Data` | source de données | `DataSource` | `BundledSeedDataSource` |
| `Data` | pont vers un framework tiers | `Adapter` | `KeychainCredentialsAdapter` |
| `Presentation` | porteur d'état d'écran | `Store` | `PortfolioStore` |
| `Presentation` | domaine → affichable | `Presenter` | `FailurePresenter` |
| `Presentation` | navigation | `Router` / `Resolver` | `Router`, `RouteResolver` |
| `Presentation` | mise en forme | `Style` | `DateStyle`, `FreshnessStyle` |
| `Features` | écran (connaît le store) | `Screen` | `ProfileScreen` |
| `Features` | vue bête (reçoit tout) | `View` | `FailureView` |
| `CoreUI` | composant réutilisable | **aucun** | `Chip`, `Surface`, `PDFPreview` |
| partout | double de test | `Stub` / `Spy` | `HTTPClientSpy` |

### Les deux exceptions, et pourquoi

**Les entités n'ont pas de suffixe.** Le domaine parle le vocabulaire du métier,
et le métier ne dit pas « PortfolioEntity ». C'est la seule couche dont les noms
devraient se lire à voix haute devant quelqu'un qui ne code pas.

**Les protocoles suivent la convention Swift, pas la nôtre.** Les *Swift API
Design Guidelines* sont explicites : un protocole qui décrit une **capacité** se
nomme en `-able`, `-ible` ou `-ing` — `Equatable`, `Collection`,
`ProgressReporting`. D'où `PortfolioReading`, `SeedProviding`,
`PreferencesStoring`. Écrire `PortfolioProtocol` ou `PortfolioPort` serait une
habitude de C# ou de Java plaquée sur un langage qui a tranché autrement — et ça
se lit mal au point d'usage : `any PortfolioReading` dit ce qu'il fait,
`any PortfolioPort` dit seulement qu'il existe.

### Tenu par une garde

`Scripts/check-naming.sh` lit chaque répertoire et refuse un type dont le nom ne
porte pas le suffixe de son rôle. Une convention que rien n'exécute est une
convention qui tient trois semaines.

---

## 22. `Core` et `CoreUI` — une seule implémentation, partout

**Demandé :** *« On pourrait avoir un package core dans lequel on a tous nos
helpers ; notre abstraction sur la gestion de Core Data ou SwiftData,
UserDefaults, si le user est offline, mettre à dispo des listeners/events
auxquels peut s'abonner toute l'app, les mécaniques d'injection de dépendances
qui doivent être communes, les protocols, les contextes — pour qu'on soit sûr
que quel que soit l'endroit dans l'app, on a une seule implémentation. »*

*« Et aussi une sorte de core-ui, dans lequel les composants réutilisables
pourront être déclarés, parfaitement configurables. Des choses comme le
previewer PDF ; et même Textual : c'est core-ui qui doit le tirer. Je ne dois pas
avoir d'`import Textual` dans les fichiers de code, mais `import CoreUI` — comme
ça, si un jour je change de bibliothèque, je n'ai pas à changer d'import. »*

### `Core` — les mécaniques, et zéro connaissance du portfolio

| Ce qu'il porte | Pourquoi là |
|---|---|
| `Clock` + `SystemClock` + `FixedClock` | trois couches injectent déjà une horloge par fermeture `() -> Date`. Trois fermetures, trois conventions |
| `KeyValueStoring` + `UserDefaultsKeyValueStore` | l'abstraction sur `UserDefaults`, qui n'a plus à être réécrite par qui en a besoin |
| `FileStore`, `StorageKey`, `StoredValue`, `LocalStoring` | l'ancien package `Persistence`, absorbé — deux abstractions du stockage, c'était exactement la duplication à éviter |
| `ConnectivityReporting` + `ConnectivityMonitor` | *« si le user est offline »*. Aujourd'hui c'est déduit d'un échec réseau ; un moniteur le **sait** avant d'essayer |
| `EventBus` | *« des listeners auxquels peut s'abonner toute l'app »* |

**Il ne dépend de rien.** Pas de `Domain`, pas de SwiftUI. Le critère d'entrée est
écrit et se vérifie :

> Entre dans `Core` ce qui **(a)** sert à au moins deux couches, **(b)** ne sait
> rien du portfolio, et **(c)** pourrait être livré dans une autre application
> sans changer d'une ligne.

⚠️ **Un `Core` est un tiroir fourre-tout en puissance.** Tout le monde en dépend,
donc tout ce qu'on y met devient global — c'est-à-dire l'inverse du découpage.
Les trois critères ci-dessus sont la seule chose qui l'en empêche, et
`ArchitectureTests` vérifie que `Core` ne gagne jamais une dépendance.

#### L'`EventBus` — et sa règle d'admission

Un bus d'événements devient du spaghetti dès qu'on y fait passer des **ordres** :
plus personne ne sait qui déclenche quoi, et la pile d'appels ne dit plus rien.

> Un événement décrit un **fait déjà arrivé** (`contentRefreshed`,
> `connectivityChanged`, `languageChanged`), dont **plusieurs parties sans lien**
> ont besoin. Un ordre (« recharge ») passe par un port, pas par le bus.

#### L'injection de dépendances — ce que `Core` apporte, et ce qu'il n'apporte pas

Il **n'apporte pas** de conteneur. L'arbitrage est déjà écrit dans
`AppEnvironment` et il tient : un enregistrement dispersé fait qu'on ne sait plus
en lisant ce qui répond à quoi, et une résolution manquante ne se découvre qu'à
l'exécution. Un `@Injected` est un localisateur de service déguisé — il cache le
graphe au lieu de le montrer.

Ce qu'il apporte est plus utile : **le vocabulaire commun d'abstractions**
(`Clock`, `KeyValueStoring`, `ConnectivityReporting`, `EventPublishing`) et **leurs
doubles**. Deux couches qui ont besoin d'une horloge dépendent du même protocole,
et la racine de composition reste le seul endroit qui décide. C'est ça, « une
seule implémentation partout ».

### `CoreUI` — les composants, et le seul à connaître les bibliothèques

| Ce qu'il porte | Ce qu'il enveloppe |
|---|---|
| `MarkdownText` | **Textual** |
| `LottieAnimation` | **Lottie** |
| `PDFPreview` | **PDFKit** |
| `Chip`, `Surface`, `MetricTile`, `Reveal`, `WrappingRow`, `Skeleton`, le verre | — |

**Aucun autre package ne déclare Lottie ni Textual.** Ce n'est pas une règle de
revue : leurs manifestes ne les nomment pas, donc `import Textual` ailleurs
répond « no such module ». Le jour où Textual est remplacé, un fichier change —
et l'interface, elle, ne bouge pas.

### `DesignSystem` cesse d'être une bibliothèque de composants

Il garde ce que son nom annonce : le **langage visuel** — tokens, couleurs,
typographie, mouvement. Rien qui dessine. Deux conséquences qui comptent :

- il reste consommable par ce qui n'est pas SwiftUI — un générateur de PDF, une
  extension, un jour une app watchOS ;
- `CoreUI` s'appuie dessus, et pas l'inverse. Un composant connaît sa palette ;
  une palette ne connaît aucun composant.

## 23. L'internationalisation — le texte quitte le code

> Arbitrage rendu le 2026-09-18, à la demande de l'auteur : *« pourquoi les vues
> n'ont pas uniquement des clés, référencées dans le truc Localizables d'Xcode
> avec des trads en français et anglais ? »*

### Ce qui existait, et pourquoi ça ne tenait plus

Le texte vivait dans des valeurs Swift — `Bilingual(fr:en:)` — qui portaient les
deux langues côte à côte. Ça tenait une promesse réelle : une traduction
manquante ne compilait pas. Et ça en cassait deux.

**SRP, au sens d'Uncle Bob** — « un module, une raison de changer », et *raison*
veut dire *acteur*. `AppChrome` changeait quand un rédacteur retouchait une
phrase **et** quand un développeur touchait à une logique de présentation. Deux
acteurs, un fichier.

**OCP** — `Bilingual(fr:en:)` est fermé à l'extension par construction : ajouter
une troisième langue, c'était éditer chacune des ~250 déclarations une par une.

### La décision

Le texte vit dans des catalogues `.xcstrings`, **un par module qui en porte**,
à côté du code qu'il habille. Une vue nomme une clé typée ; le mot est dans le
catalogue, éditable sans ouvrir un fichier Swift.

```
ViewKit/Resources/            les libellés partagés + l'écran Réglages
Decisions/Resources/          les libellés autour d'une décision
Features/<Nom>/Resources/     les décisions annotées sur cet écran
Features/Engineering/         ce que l'application dit d'elle-même
```

### Les trois règles qui font que ce n'est pas « juste un .xcstrings »

**1. Résolu sur la langue choisie, pas sur celle de l'appareil.** C'était la
seule objection sérieuse à un catalogue, et elle ne visait pas le catalogue mais
son *lookup par défaut*. `TextCatalogue` passe par le sous-bundle `<code>.lproj`,
donc sur la langue **du contenu servi**. Une suite l'épingle, y compris le repli
d'un code inconnu — qui va vers la langue **source** et non vers celle de
l'appareil, sans quoi le défaut rentrerait par la fenêtre.

**2. Seule la couche vue résout.** Résoudre demande un bundle, un catalogue
compilé et la langue à l'écran : trois détails de livraison. `Presentation` ne
déclare donc pas `Localization`, et `import Localization` y répond « no such
module ». Les couches basses rendent des **valeurs** : `PhaseFailure` porte la
cause et le chemin du champ, `AppSection` un cas, `ArchitecturePattern.Criterion`
un cas. Le mapping vers une clé vit dans `ViewKit`.

**3. Rien n'énumère les langues.** Ni un type, ni une vue. La liste est ce que le
catalogue compilé contient (`TextCatalogue.languages`). `\.contentLanguage` est
**posé une fois** par la scène et **lu par deux résolveurs** : `@Localized` pour
les clés, `@LocalizedDecision` pour les phrases d'une décision. Aucun écran n'en
voit une. `check-strings.sh` le refuse, mutation testé.

### Pourquoi `Localization` est un package et pas un coin de `Core`

`Core` porte aussi le stockage disque et la connectivité, et l'invariant central
dit qu'**aucun écran ne les atteint**. L'y ranger aurait acheté une commodité au
prix de l'accès disque pour toutes les vues de l'application. Ségrégation des
interfaces, tenue par le manifeste plutôt que par la bonne volonté.

### Ce que ça a coûté, et comment c'est racheté

Une traduction manquante n'est plus une erreur de compilation : la clé s'affiche
à l'écran, en silence. `check-strings.sh` rachète ça en CI — et va plus loin que
`Bilingual` ne savait aller :

| ce qui échoue | ce que `Bilingual` en disait |
|---|---|
| une traduction vide ou non `translated` | erreur de compilation |
| une clé requise absente d'un catalogue | erreur de compilation |
| une **clé morte** que rien n'atteint | rien |
| une **langue absente d'un seul** catalogue | rien |
| une phrase écrite en dur dans une vue | rien |
| une vue qui lit `\.contentLanguage` | rien |
| un `case .french` n'importe où | rien |

### Le défaut que ça a fait sortir

```swift
language == .french ? "\(count) chantiers" : "\(count) workstreams"
```

Faux au singulier — « 1 chantiers ». Le pluriel revient à la plateforme
(*Vary by Plural*), qui applique la règle **de la langue demandée** : le français
met 0 et 1 au singulier, l'anglais seulement 1.

### Le vocabulaire, au passage

« Coulisses » / `Backstage` était une métaphore de théâtre dans un portfolio
professionnel, et elle écrasait deux concepts. L'onglet porte des couches, des
défis, des parcours de code et l'arbitrage des dépendances : c'est de
l'**ingénierie**. L'annotation sur un composant porte le rôle, la justification,
ce qui a été écarté, quand l'employer et le piège : c'est la structure exacte
d'un **ADR**, donc une `DesignDecision`.

`Chrome` était du jargon de navigateur sans contrepartie : c'est `interface`.

⚠️ **Un mot du contrat de contenu ne se renomme pas d'un seul côté.** `eyebrow` a
été renommé en `overline` et la suite l'a refusé : c'est un champ servi par
l'API. Rendu tel quel — la décision, si elle se prend, se prend sur les trois
dépôts à la fois.
