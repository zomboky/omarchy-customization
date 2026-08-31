#!/usr/bin/env bash
# Installe l'outil window-opacity.
#
#   - copie bin/window-opacity            -> ~/.local/bin/window-opacity
#   - cree  ~/.config/hypr/window-opacity.lua  (vide s'il n'existe pas)
#   - ajoute  require("hypr.window-opacity")   a ~/.config/hypr/hyprland.lua
#   - ajoute 2 keybindings a ~/.config/hypr/bindings.lua (unbind des defauts d'abord) :
#         SUPER + =            -> window-opacity up     (plus opaque)
#         SUPER SHIFT + =      -> window-opacity down   (plus transparent)
#     (reset : commande 'window-opacity reset', sans raccourci)
#   - hyprctl reload
#
# Idempotent : chaque bloc est encadre de marqueurs et n'est ajoute qu'une fois.
# Tout fichier de ~/.config touche est copie en <fichier>.bak.<epoch> d'abord.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_dst="$HOME/.local/bin/window-opacity"
hypr_dir="${config_dir}/hypr"
hyprland_lua="${hypr_dir}/hyprland.lua"
bindings_lua="${hypr_dir}/bindings.lua"
generated_lua="${hypr_dir}/window-opacity.lua"

command -v jq >/dev/null || { echo "window-opacity : 'jq' requis (omarchy pkg add jq)" >&2; exit 1; }
[[ -f "${hyprland_lua}" ]] || { echo "window-opacity : ${hyprland_lua} introuvable — pas Omarchy ?" >&2; exit 1; }
[[ -f "${bindings_lua}" ]] || { echo "window-opacity : ${bindings_lua} introuvable — pas Omarchy ?" >&2; exit 1; }

backup() { # backup <file>
  local f="$1" b
  b="${f}.bak.$(date +%s)"
  local i=1
  while [[ -e "${b}" ]]; do b="${f}.bak.$(date +%s)-${i}"; ((i++)); done
  cp "${f}" "${b}"
  echo "window-opacity : sauvegarde $(basename "${f}") -> $(basename "${b}")"
}

# 1. le script
install -Dm755 "${here}/bin/window-opacity" "${bin_dst}"
echo "window-opacity : installe ${bin_dst}"

# 2. fichier de regles genere (stub vide si absent)
if [[ ! -f "${generated_lua}" ]]; then
  cat >"${generated_lua}" <<'EOF'
-- Genere par window-opacity — NE PAS EDITER A LA MAIN.
-- Regenere a chaque 'window-opacity set|up|down|reset|apply'.
-- (aucune opacite memorisee)
EOF
  echo "window-opacity : cree ${generated_lua}"
else
  echo "window-opacity : ${generated_lua} existe deja — laisse tel quel"
fi

# 3. require() dans hyprland.lua
if grep -q 'require("hypr.window-opacity")' "${hyprland_lua}"; then
  echo "window-opacity : hyprland.lua charge deja le module — laisse tel quel"
else
  backup "${hyprland_lua}"
  {
    echo ""
    echo '-- >>> window-opacity (opacites memorisees par application)'
    echo 'require("hypr.window-opacity")'
    echo '-- <<< window-opacity'
  } >>"${hyprland_lua}"
  echo "window-opacity : ajoute require(\"hypr.window-opacity\") a hyprland.lua"
fi

# 4. keybindings dans bindings.lua
if grep -q '>>> window-opacity' "${bindings_lua}"; then
  echo "window-opacity : bindings.lua a deja les raccourcis — laisse tel quel"
else
  backup "${bindings_lua}"
  {
    echo ""
    echo '-- >>> window-opacity'
    echo '-- Touche "=" (code:21). Omarchy binde le resize par KEYCODE'
    echo '-- ("SUPER + code:21" = "Shrink window left", "SUPER + SHIFT + code:21" ='
    echo '-- "Expand window down") : il faut unbind la forme keycode, pas "SUPER + EQUAL".'
    echo '-- On rebinde aussi en code:21 pour rester independant du clavier (AZERTY :'
    echo '-- SHIFT + "=" donne le keysym "plus", pas "equal").'
    echo 'hl.unbind("SUPER + code:21")'
    echo 'hl.unbind("SUPER + SHIFT + code:21")'
    echo 'o.bind("SUPER + code:21", "Opacite +", "$HOME/.local/bin/window-opacity up")'
    echo 'o.bind("SUPER + SHIFT + code:21", "Opacite -", "$HOME/.local/bin/window-opacity down")'
    echo "-- reset : lancer 'window-opacity reset' (pas de raccourci clavier)"
    echo '-- SUPER+ALT+"=" / SUPER+CTRL+"=" redimensionnent encore (variants "a little"/"a lot").'
    echo '-- <<< window-opacity'
  } >>"${bindings_lua}"
  echo "window-opacity : ajoute SUPER+= (plus opaque) / SUPER+SHIFT+= (plus transparent) a bindings.lua"
fi

# 5. recharge Hyprland + valide
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null
  errs="$(hyprctl configerrors 2>/dev/null | grep -v '^ok$' || true)"
  if [[ -n "${errs}" ]]; then
    echo "window-opacity : ATTENTION — hyprctl configerrors signale :" >&2
    echo "${errs}" >&2
  else
    echo "window-opacity : hyprctl reload OK, aucune erreur de config"
  fi
else
  echo "window-opacity : session Hyprland absente — rechargez avec 'hyprctl reload' plus tard"
fi

echo "window-opacity : termine. Focalisez une fenetre et pressez SUPER+' pour la rendre transparente."
