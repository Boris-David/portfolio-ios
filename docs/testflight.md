# Livrer sur TestFlight

Une seule commande, et rien de secret dans ce dépôt.

```bash
git tag v1.0.0 && git push --tags     # ce qui déclenche la livraison
bundle exec fastlane beta             # la même chose, depuis un portable
```

## Ce qui tourne, dans cet ordre

1. `bootstrap.sh` — le `.xcodeproj` est généré et non versionné, donc il
   n'existe pas sur un runner neuf, et il est périmé partout ailleurs.
2. **La suite complète.** Avant la signature, pas après : un test qui échoue ne
   doit jamais atteindre l'étape qui coûte douze minutes et un certificat.
3. `match` — restaure les certificats depuis leur dépôt, en **lecture seule** en
   CI. Un runner capable de régénérer du matériel de signature est un runner
   capable d'invalider toutes les autres machines.
4. Le numéro de build vient du **numéro de run** GitHub. Un numéro committé,
   c'est deux branches qui se disputent le même et un rejet à l'upload.
5. `upload_to_testflight`, sans attendre le traitement d'Apple — il prend une
   demi-heure et un job qui patiente ne rapporte rien.

## Les quatre secrets, et comment on les fabrique

Aucun ne vit ici. Ils se posent dans **Settings → Secrets and variables →
Actions** du dépôt.

| Secret | D'où il vient |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API. Créer une clé **App Manager**. C'est l'identifiant à dix caractères affiché à côté. |
| `APP_STORE_CONNECT_ISSUER_ID` | Sur la même page, en haut : un UUID, le même pour tout le compte. |
| `APP_STORE_CONNECT_KEY` | Le fichier `.p8` téléchargé à la création — **une seule fois, Apple ne le redonne pas**. À coller en base64 : `base64 -i AuthKey_<KEY_ID>.p8 \| pbcopy`. C'est bien le **contenu**, pas un chemin. |
| `MATCH_PASSWORD` | La phrase choisie au premier `fastlane certificates`. C'est elle qui déchiffre le dépôt de certificats ; perdue, il faut tout régénérer. |

Plus un accès en lecture au dépôt de certificats :
`MATCH_GIT_BASIC_AUTHORIZATION` = `base64(<user>:<token à portée repo:read>)`.

> ⚠️ Ces valeurs ne se collent **jamais** dans une conversation, un fichier, ni
> un message de commit. Elles vont de l'endroit qui les fabrique à l'interface
> GitHub, et nulle part ailleurs. `./Scripts/check-secrets.sh` refuse le commit
> qui en porterait une.

## La première fois, depuis un portable

Le dépôt de certificats est **dédié au portfolio** — jamais celui d'un autre
projet, voir `.claude/rules/scope-isolation.md`.

```bash
gh repo create Boris-David/portfolio-certificates --private
bundle exec fastlane certificates      # crée et scelle le certificat + le profil
```

Cette voie refuse de s'exécuter en CI, exprès.

## Ce que ça ne fait pas

Pas de publication sur l'App Store, pas de distribution externe, pas de notes de
version automatiques. TestFlight interne, et la décision de publier reste une
décision.
