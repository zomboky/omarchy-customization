#!/usr/bin/env bash
# Desinstalle window-opacity : retire les blocs marques de hyprland.lua et
# bindings.lua (sauvegarde horodatee d'abord), supprime le script, le fichier
# de regles genere et le stockage JSON.

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_dst="$HOME/.local/bin/window-opacity"
hypr_dir="${config_dir}/hypr"
hyprland_lua="${hypr_dir}/hyprland.lua"
bindings_lua="${hypr_dir}/bindings.lua"
generated_lua="${hypr_dir}/window-opacity.lua"
store="${config_dir}/omarchy/window-opacity.json"

backup() {
  local f="$1" b
  b="${f}.bak.$(date +%s)"
  local i=1
  while [[ -e "${b}" ]]; do b="${f}.bak.$(date +%s)-${i}"; ((i++)); done
  cp "${f}" "${b}"
  echo "window-opacity : sauvegarde $(basename "${f}") -> $(basename "${b}")"
}

strip_block() { # strip_block <file>  — retire les lignes entre les marqueurs >>> / <<< window-opacity
  local f="$1"
  [[ -f "${f}" ]] || return 0
  grep -q '>>> window-opacity' "${f}" || { echo "window-opacity : rien a retirer de $(basename "${f}")"; return 0; }
  backup "${f}"
  sed -i '/-- >>> window-opacity/,/-- <<< window-opacity/d' "${f}"
  # nettoie une eventuelle ligne vide en trop laissee juste avant
  sed -i -e :a -e '/^\n*$/{$d;N;ba}' "${f}"
  echo "window-opacity : bloc retire de $(basename "${f}")"
}

strip_block "${bindings_lua}"
strip_block "${hyprland_lua}"

rm -f "${bin_dst}" "${generated_lua}" "${store}"
echo "window-opacity : supprime ${bin_dst}, ${generated_lua}, ${store}"

if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null
  echo "window-opacity : hyprctl reload OK"
fi
echo "window-opacity : desinstalle."
