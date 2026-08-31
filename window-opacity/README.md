# window-opacity

Régler l'**opacité d'une fenêtre** à la volée depuis le clavier, et la
**mémoriser par application** — la valeur est réappliquée à chaque ouverture
d'une fenêtre de cette app, après un `hyprctl reload`, et après une
reconnexion.

Hyprland n'a pas de « retenir l'opacité par app » intégré : l'opacité passe par
des *window rules* (statiques, dans la config) ou par une commande ponctuelle
qui ne survit pas au reload. `window-opacity` fait le pont : une commande ajuste
la fenêtre focalisée **immédiatement** *et* écrit une règle persistante.

## Utilisation

| Raccourci | Commande | Effet |
| --- | --- | --- |
| `SUPER + =` | `window-opacity up` | +5 % pour l'app focalisée (plus opaque) |
| `SUPER SHIFT + =` | `window-opacity down` | −5 % (plus transparente) |

`SUPER + =` et `SUPER SHIFT + =` étaient les défauts Omarchy *« Shrink window
left »* / *« Expand window down »* ; l'installeur les `hl.unbind` d'abord.
`SUPER + -` / `SUPER SHIFT + -` redimensionnent toujours.

En ligne de commande (le script est dans `~/.local/bin`) :

```bash
window-opacity reset        # oublie l'app focalisée -> défaut Omarchy (pas de raccourci)
window-opacity set 0.85     # valeur explicite : 0.85, 85 ou 85%
window-opacity status       # app focalisée + opacité mémorisée
window-opacity list         # toutes les opacités mémorisées
window-opacity apply        # regénère + réapplique tout (au démarrage au besoin)
```

Bornes : **30 % → 100 %**, pas de **5 %**. Le « défaut Omarchy » est
`0.985 0.96` (actif / inactif) sauf pour les apps qui l'ont déjà surchargé
(navigateurs, lecteurs vidéo, jeux…).

## Comment ça marche

Deux mécanismes, tenus synchronisés par le script :

1. **À chaud** — `hyprctl eval 'hl.window_rule({ match = { class = ... },
   opacity = "0.85 override" })'`. Avec le parseur Lua d'Hyprland (≥ 0.5x) les
   *window rules* sont réactives : la règle touche les fenêtres **déjà
   ouvertes** de cette classe, pas seulement les suivantes.
2. **Persistant** — le script (re)génère `~/.config/hypr/window-opacity.lua`,
   une par une les règles :

   ```lua
   o.window({ class = [[^(Foo)$]] }, { tag = "-default-opacity", opacity = [[0.85 override]] })
   ```

   Ce fichier est chargé par `~/.config/hypr/hyprland.lua` via
   `require("hypr.window-opacity")` (ajouté par l'installeur), **après** les
   défauts Omarchy — donc `override` gagne. Le préfixe `hypr.` est dans la
   liste de rechargement du bootstrap d'Omarchy : la règle est donc rejouée à
   chaque `hyprctl reload`.

La source de vérité est `~/.config/omarchy/window-opacity.json`
(`{ "<class>": 0.85 }`) ; le `.lua` en est dérivé.

L'app est identifiée par sa **classe Hyprland** (`hyprctl activewindow -j`,
champ `class`). `window-opacity status` l'affiche pour la fenêtre courante.

## Prérequis

- Omarchy / Hyprland ≥ 0.5x (parseur Lua, `hl.window_rule`).
- `jq` — `omarchy pkg add jq`.
- `hyprctl`, `awk`, `sed`, `column` — base système.

## Installation

Depuis la racine du dépôt :

```bash
./install.sh window-opacity
```

ou en autonome : `./window-opacity/install.sh`.

L'installeur :

1. copie `bin/window-opacity` → `~/.local/bin/window-opacity` (mode 755) ;
2. crée `~/.config/hypr/window-opacity.lua` (vide s'il n'existe pas) ;
3. ajoute `require("hypr.window-opacity")` à `~/.config/hypr/hyprland.lua` ;
4. ajoute les 2 raccourcis (+ 2 `hl.unbind`) à `~/.config/hypr/bindings.lua` ;
5. `hyprctl reload` puis vérifie `hyprctl configerrors`.

**Idempotent** : chaque bloc ajouté est encadré par des marqueurs
`-- >>> window-opacity` / `-- <<< window-opacity` et n'est écrit qu'une fois.
Tout fichier de `~/.config/` modifié est copié en `<fichier>.bak.<epoch>`
avant.

## Configuration

| Envie | Où | Changer |
| --- | --- | --- |
| Autre pas que 5 % | `bin/window-opacity` | `STEP=0.10` |
| Autres bornes | `bin/window-opacity` | `MIN` / `MAX` |
| Autres touches | `~/.config/hypr/bindings.lua` (bloc `window-opacity`) | éditer les `o.bind` (ajuster les `hl.unbind`) |
| Cibler `initialClass` plutôt que `class` | `bin/window-opacity` | `active_class()` : `.initialClass` |

Après édition de `bin/window-opacity`, relancer l'installeur (ou recopier le
fichier sur `~/.local/bin/window-opacity`).

## Fichiers

| Chemin | Rôle |
| --- | --- |
| `~/.local/bin/window-opacity` | le script |
| `~/.config/omarchy/window-opacity.json` | source de vérité (`class` → opacité) |
| `~/.config/hypr/window-opacity.lua` | règles générées, chargées par Hyprland |
| `~/.config/hypr/hyprland.lua` | contient le `require(...)` (sauvegardé à l'install) |
| `~/.config/hypr/bindings.lua` | contient les 2 raccourcis (sauvegardé à l'install) |

## Désinstallation

```bash
./window-opacity/uninstall.sh
```

Retire les blocs marqués de `hyprland.lua` et `bindings.lua` (sauvegarde
d'abord), supprime le script, le `.lua` généré et le JSON, puis
`hyprctl reload`.

## Limites

- **Par classe**, pas par fenêtre : toutes les fenêtres d'une même app
  partagent l'opacité mémorisée.
- Les apps qui se lancent avec une classe vide puis la définissent tard
  peuvent n'être prises en compte qu'après un second focus + `down`.
- `reset` fait un `hyprctl reload` (pour retirer proprement la règle
  dynamique) ; `up`/`down`/`set` non, ils appliquent à chaud.
- Le champ `class` de certaines webapps Chrome contient le profil
  (`chrome-…-Default`) : l'opacité suit ce profil précis.
