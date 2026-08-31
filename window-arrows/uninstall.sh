#!/usr/bin/env bash
# Retire le bloc window-arrows de ~/.config/hypr/bindings.lua (sauvegarde
# horodatée d'abord) et recharge Hyprland. Les défauts Omarchy
# (SUPER + flèches = focus voisin, SUPER + CTRL + flèches = grouped focus)
# reviennent au prochain reload.

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings_lua="${config_dir}/hypr/bindings.lua"

[[ -f "${bindings_lua}" ]] || { echo "window-arrows : ${bindings_lua} introuvable"; exit 0; }

if ! command grep -q '>>> window-arrows' "${bindings_lua}"; then
  echo "window-arrows : aucun bloc à retirer"
  exit 0
fi

backup="${bindings_lua}.bak.$(date +%s)"
i=1; while [[ -e "${backup}" ]]; do backup="${bindings_lua}.bak.$(date +%s)-${i}"; ((i++)); done
cp "${bindings_lua}" "${backup}"
echo "window-arrows : sauvegarde bindings.lua -> $(basename "${backup}")"

sed -i '/-- >>> window-arrows/,/-- <<< window-arrows/d' "${bindings_lua}"
sed -i -e :a -e '/^\n*$/{$d;N;ba}' "${bindings_lua}"
echo "window-arrows : bloc retiré"

if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null
  echo "window-arrows : hyprctl reload OK"
fi
