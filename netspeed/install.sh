#!/usr/bin/env bash
# Install the netspeed indicator into the Omarchy bar.
#
#   - copies bin/netspeed          -> ~/.config/omarchy/bar/scripts/netspeed
#   - adds a "netspeed" command widget to bar.layout.right in shell.json,
#     right after omarchy.network (idempotent, timestamped backup first)
#
# Safe to re-run: an existing netspeed entry is left untouched.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
script_dst="${config_dir}/bar/scripts/netspeed"
shell_json="${config_dir}/shell.json"

command -v jq >/dev/null || { echo "netspeed: 'jq' is required (omarchy pkg add jq)" >&2; exit 1; }
[[ -f "${shell_json}" ]] || { echo "netspeed: ${shell_json} not found — is this Omarchy?" >&2; exit 1; }

# 1. script
install -Dm755 "${here}/bin/netspeed" "${script_dst}"
echo "netspeed: installed ${script_dst}"

# 2. bar widget entry
if jq -e '[.bar.layout[]?[]? | select(.id == "netspeed")] | length > 0' "${shell_json}" >/dev/null; then
  echo "netspeed: shell.json already has a 'netspeed' widget — left as is"
  exit 0
fi

backup="${shell_json}.bak.$(date +%s)"
i=1; while [[ -e "${backup}" ]]; do backup="${shell_json}.bak.$(date +%s)-${i}"; ((i++)); done
cp "${shell_json}" "${backup}"
echo "netspeed: backed up shell.json -> ${backup}"

tmp="$(mktemp)"
jq '
  ({ id: "netspeed", type: "command",
     exec: "~/.config/omarchy/bar/scripts/netspeed",
     interval: 2, tooltip: "Network throughput",
     onClick: "omarchy-network-status" }) as $w
  | .bar.layout.right |= (
      (map(.id) | index("omarchy.network")) as $i
      | if $i == null then . + [$w] else .[0:$i+1] + [$w] + .[$i+1:] end
    )
' "${shell_json}" > "${tmp}"

jq -e . "${tmp}" >/dev/null || { echo "netspeed: generated invalid JSON, aborting" >&2; rm -f "${tmp}"; exit 1; }
mv "${tmp}" "${shell_json}"
echo "netspeed: added widget to bar.layout.right (after omarchy.network)"
echo "netspeed: done — the bar hot-reloads; run 'omarchy restart shell' if it doesn't show."
