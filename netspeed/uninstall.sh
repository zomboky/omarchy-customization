#!/usr/bin/env bash
# Remove the netspeed indicator from the Omarchy bar.
#   - drops the "netspeed" entry from shell.json (timestamped backup first)
#   - deletes ~/.config/omarchy/bar/scripts/netspeed and its state file

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
script_dst="${config_dir}/bar/scripts/netspeed"
shell_json="${config_dir}/shell.json"
state_file="${XDG_RUNTIME_DIR:-/tmp}/omarchy-netspeed.state"

command -v jq >/dev/null || { echo "netspeed: 'jq' is required" >&2; exit 1; }

if [[ -f "${shell_json}" ]] && jq -e '[.bar.layout[]?[]? | select(.id == "netspeed")] | length > 0' "${shell_json}" >/dev/null; then
  backup="${shell_json}.bak.$(date +%s)"
  i=1; while [[ -e "${backup}" ]]; do backup="${shell_json}.bak.$(date +%s)-${i}"; ((i++)); done
  cp "${shell_json}" "${backup}"
  tmp="$(mktemp)"
  jq '.bar.layout |= map_values(map(select(.id != "netspeed")))' "${shell_json}" > "${tmp}"
  mv "${tmp}" "${shell_json}"
  echo "netspeed: removed widget from shell.json (backup ${backup})"
else
  echo "netspeed: no 'netspeed' widget in shell.json"
fi

rm -f "${script_dst}" "${state_file}"
echo "netspeed: removed ${script_dst}"
