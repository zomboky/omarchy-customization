#!/usr/bin/env bash
# Installe le schéma de flèches window-arrows dans ~/.config/hypr/bindings.lua :
#
#   SUPER + flèches         -> redimensionner la fenêtre  (était : focus voisin)
#   SUPER + CTRL + flèches   -> focus de la fenêtre voisine (repris de "grouped focus")
#   SUPER + SHIFT + flèches  -> échanger les fenêtres  (défaut Omarchy, inchangé)
#
# Idempotent : le bloc est encadré de marqueurs et n'est ajouté qu'une fois.
# bindings.lua est copié en bindings.lua.bak.<epoch> avant modification.

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings_lua="${config_dir}/hypr/bindings.lua"

[[ -f "${bindings_lua}" ]] || { echo "window-arrows : ${bindings_lua} introuvable — pas Omarchy ?" >&2; exit 1; }

if command grep -q '>>> window-arrows' "${bindings_lua}"; then
  echo "window-arrows : bindings.lua a déjà le bloc — laissé tel quel"
  exit 0
fi

backup="${bindings_lua}.bak.$(date +%s)"
i=1; while [[ -e "${backup}" ]]; do backup="${bindings_lua}.bak.$(date +%s)-${i}"; ((i++)); done
cp "${bindings_lua}" "${backup}"
echo "window-arrows : sauvegarde bindings.lua -> $(basename "${backup}")"

cat >>"${bindings_lua}" <<'EOF'

-- >>> window-arrows
-- SUPER + fleches : etait "Focus on X window" -> redimensionnement de la fenetre.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
o.bind("SUPER + LEFT",  "Largeur -", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + RIGHT", "Largeur +", hl.dsp.window.resize({ x = 100,  y = 0, relative = true }))
o.bind("SUPER + UP",    "Hauteur -", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + DOWN",  "Hauteur +", hl.dsp.window.resize({ x = 0, y = 100,  relative = true }))
-- SUPER + CTRL + fleches : focus de la fenetre voisine (repris de "Move grouped window focus").
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
hl.unbind("SUPER + CTRL + UP")
hl.unbind("SUPER + CTRL + DOWN")
o.bind("SUPER + CTRL + LEFT",  "Focus fenetre gauche",     hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + CTRL + RIGHT", "Focus fenetre droite",     hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + CTRL + UP",    "Focus fenetre au-dessus",  hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + CTRL + DOWN",  "Focus fenetre en dessous", hl.dsp.focus({ direction = "d" }))
-- SUPER + SHIFT + fleches : "Swap window" (echanger les fenetres cote a cote) -> defaut Omarchy, inchange.
-- <<< window-arrows
EOF
echo "window-arrows : bloc ajouté à bindings.lua"

if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null
  errs="$(hyprctl configerrors 2>/dev/null | command grep -v '^ok$' || true)"
  if [[ -n "${errs}" ]]; then
    echo "window-arrows : ATTENTION — hyprctl configerrors signale :" >&2
    echo "${errs}" >&2
  else
    echo "window-arrows : hyprctl reload OK, aucune erreur de config"
  fi
else
  echo "window-arrows : session Hyprland absente — rechargez avec 'hyprctl reload' plus tard"
fi
