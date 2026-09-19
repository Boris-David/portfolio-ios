---
paths:
  - "Packages/DesignSystem/Sources/**"
  - "Packages/CoreUI/Sources/**"
  - "Packages/Features/Sources/**"
  - "App/**"
---

# Interface — design system, annotations, compatibilité

> Chargée quand on touche à une vue, au design system ou aux annotations de
> décision.
>
> ⚠️ Les `paths:` ci-dessus désignaient `Packages/AmissanKit/`, un dossier qui
> n'existe plus depuis la séparation en un package par couche. La règle ne se
> chargeait donc **plus jamais**. Une règle scopée sur un chemin mort ne dit
> rien et ne prévient pas.

## Le partage qui rend l'app native

**`List` quand la donnée est homogène et en lignes** — le parcours, un
formulaire de réglages. **Composition libre quand le contenu est éditorial** —
une étude de cas, un essai, le profil.

Une `List` donne gratuitement, et correctement, ce qu'un `VStack` de cartes
re-dérive à l'œil : séparateurs système et leurs encarts, en-têtes de section,
métriques de ligne aux tailles d'accessibilité, recyclage.

Corollaire : **un dépliage dans une liste est un `DisclosureGroup`**, pas le
dépliage fait main ci-dessous. Une sous-vue à hauteur nulle se bat avec la mesure
de la ligne, et le séparateur se pose là où le contenu replié se trouvait.

## La page possède sa gouttière

`.padding(.horizontal, Tokens.Space.s5)` ne s'écrit pas dans un bloc. Il était
recollé à la main à **vingt-et-un endroits** — une propriété de la page recopiée
sur chaque chose posée dessus, et un bloc qui l'oubliait se collait au bord
pendant que ses voisins ne le faisaient pas.

`SectionScrollView` la pose une fois, avec la colonne de lecture et l'encart du
bas. Un bloc qui doit déborder — un rayon qui défile latéralement — l'annule
localement et le dit.

## Une seule ancre de présentation

`Modal` est un type, et le style (`sheet` / `fullScreen`) est une **propriété du
modal**. Un appelant demande `present(.resume)` ; il ne choisit pas comment.

Deux types, c'était deux résolveurs, deux actions d'environnement et **deux
ancres** — dont une qui ne réappliquait pas `SceneEnvironment`. Un écran présenté
est hébergé hors de l'arbre qui le présente et **n'hérite de rien** : c'est un
crash, pas un détail, et il avait déjà été payé une fois.

⚠️ Corollaire : `.decisionOverlay()` aussi se repose dans une feuille. L'écran
Réglages émettait trois annotations que rien ne dessinait.

## Liquid Glass : la couche navigation, et elle seule

Liquid Glass est un matériau de **navigation** : barres, contrôles flottants,
accessoires. Posé sur du contenu, il dégrade le contraste et brouille la
hiérarchie — tout se met à flotter, donc plus rien ne ressort.

La règle est tenue par la nomenclature : il n'existe pas de `contentGlass()`.

**Ne jamais semer de `if #available(iOS 26, *)` dans une vue.** L'intention se
nomme (`.navigationGlass()`), et le rendu se décide dans `Glass.swift`. Au bout
de trente écrans, personne ne sait plus ce que voit un utilisateur d'iOS 18.

⚠️ **`glassEffect` s'applique à la vue, jamais à un fond posé derrière.** Le
verre d'iOS 26 n'est pas une couche qu'on empile : c'est un traitement de la vue
à laquelle il est appliqué, et il compose son propre contenu. Mis dans un
`.background { … }`, il **recouvre le libellé** — ça compile, ça n'avertit de
rien, et le bouton apparaît vide.

⚠️ Un bouton **principal** ne se rend pas pareil dans les deux mondes.
`Glass.tint(_:)` garantit la lisibilité sur iOS 26 ; la même teinte à faible
opacité sur un matériau translucide donne, en thème clair sur iOS 18, du blanc
sur du pâle. Le repli est un **aplat d'accent**. Mesuré à l'écran.

## La colonne de lecture est bornée

`.readableWidth()` sur le contenu de chaque écran. Une ligne se lit bien autour
de **65 caractères** ; au-delà, l'œil perd le début de la ligne suivante en
revenant à la marge.

Sans effet sur iPhone, décisif sur iPad : sans cette borne, un paragraphe y
courait sur **mille points**. C'est la même règle que le site, exprimée là-bas en
`ch`.

## L'application vise iPhone **et** iPad

`TARGETED_DEVICE_FAMILY: "1,2"`. Vérifié sur iPad Pro 13" en portrait, sur les
quatre onglets — la grille d'applications y passe à trois colonnes toute seule,
grâce à `.adaptive`.

⚠️ **`.readableWidth()` vaut aussi pour une `List`.** Sans elle, une ligne de
texte y faisait **1 300 points** sur iPad Pro 13". La borne va sur la liste, le
papier autour : `readableWidth()` garde un cadre extérieur pleine largeur, donc
le fond atteint les deux bords et seules les lignes sont resserrées.

**Non vérifié** : le paysage et le multitâche en écran partagé. Une colonne de
lecture unique y est robuste par construction, mais ça reste à regarder avant de
le tenir pour acquis.

## Les polices sont natives

New York (`design: .serif`) pour les titres, SF Pro pour le texte, SF Mono pour
le code. Pas les polices du site : une police personnalisée ne suit Dynamic Type
que si on la câble, et ce câblage est ce qu'on oublie de tester en accessibilité
extra-large.

L'échelle de `design/tokens.json` est déjà alignée sur Dynamic Type — base 17.

## Le mouvement

Les courbes viennent des tokens : **la même sensation que sur le site**.

`prefers-reduced-motion` **supprime** le mouvement, il ne l'atténue pas. Réduire
de moitié une animation qui donne la nausée donne toujours la nausée.

Un bloc `.reveal()` doit rester lisible si l'animation ne joue jamais : une vue
restée à `opacity: 0` parce qu'un observateur ne s'est pas déclenché est du
contenu perdu.

## Le dépliage

Le contenu replié **reste dans l'arbre de vues**, à hauteur nulle, sous un
`.clipped()`. Deux conséquences : la recherche système et VoiceOver l'atteignent,
et la transition part d'un état qui existe.

Sans `.clipped()`, il déborde par-dessus les cartes voisines pendant l'animation
— visible seulement au ralenti.

## Les annotations de décision

`.decision(note)` pose une annotation. La couche `.decisionOverlay()` se pose
**une fois par écran**, au niveau le plus haut, là où la géométrie est connue.

⚠️ **`transformAnchorPreference`, jamais `anchorPreference`.** Le second
*remplace* la préférence du sous-arbre : une annotation posée sur un conteneur
efface toutes celles qu'il contient. Observé — l'annotation du `ScrollView`
faisait disparaître celles du logo et des boutons, sans erreur.

⚠️ **Un `UIViewRepresentable` ne rapporte pas toujours le cadre qu'on lui
impose.** L'ancre relevée sur la vue Lottie désignait une bande vide sous elle.
Annoter le conteneur, pas le pont. Le cadre en pointillés dessiné en mode
annotations rend ce genre d'écart immédiatement visible — c'est aussi à ça qu'il
sert.

Une note sans `rejected` n'est pas encore une décision, c'est un réflexe.

## L'accessibilité n'est pas une passe finale

- un chiffre et sa légende sont **un** élément (`children: .combine`), sinon
  VoiceOver annonce « 6 » puis, plus loin, « d'ingénierie iOS » ;
- toute cible tactile fait au moins `Tokens.Accessibility.minimumTouchTarget` —
  la pastille d'annotation fait 26 points de côté et 44 de zone tactile ;
- un élément décoratif est **masqué**, pas annoncé « image ».

## Le titre de navigation

Un grand titre UIKit **ne passe pas à la ligne** : il tronque. Donc un titre long
reste dans le contenu, qui sait envelopper, et la barre porte la forme courte —
une trentaine de caractères. L'inverse a été essayé sur l'étude de cas et sur
l'écran d'ingénierie : le titre complet n'apparaissait alors nulle part.

Le grand titre est habillé en New York une seule fois, par la proxy d'apparence
(`NavigationAppearance`), et **seul l'attribut de police** est posé — toucher
`standardAppearance` remplacerait aussi le fond, qui est le Liquid Glass que le
système dessine gratuitement.

## Regarder l'écran fait partie du travail

Une quinzaine de défauts de cette base ne se voyaient qu'en capture :

- `UILaunchScreen` absent → mode de compatibilité, 603 points utilisés sur 874 ;
- l'annotation qui effaçait ses voisines ;
- l'ancre d'un `UIViewRepresentable` qui désignait une bande vide ;
- le chrome français au-dessus d'un contenu anglais ;
- le bouton principal illisible sur iOS 18 en thème clair ;
- puis, en le corrigeant, le libellé **disparu** sur iOS 26 — vu sur iPad, et
  retrouvé ensuite sur iPhone où je l'avais pris pour un bouton caché derrière la
  barre d'onglets ;
- `> 99,8` coupé sur **trois lignes** dans une rangée de trois métriques ;
- deux grands titres en New York 34 pt à quarante points d'écart, l'œil prenant
  le second pour un sous-titre du premier ;
- un `Spacer` clouant un lien au bas d'une carte, ouvrant une bande de vide —
  **visible sur iPad seulement**, parce que sur iPhone le texte remplissait la
  colonne par hasard ;
- une colonne de titre de trois mots de large à côté d'une icône de 76 pt, à AX5.

Aucun n'a produit d'avertissement. Et le dernier rappelle qu'**une capture mal
lue vaut une régression non vue** : regarder ne suffit pas, il faut regarder le
bon endroit.
