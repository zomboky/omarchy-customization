#!/usr/bin/env bash
# Install every Omarchy customization in this repo, or just the ones named.
#
#   ./install.sh                # install all tools
#   ./install.sh netspeed       # install only netspeed
#
# Each tool lives in its own directory with its own install.sh; this script
# just dispatches to them. Every tool installer is idempotent and backs up
# anything it touches under ~/.config/.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Tool = any subdirectory containing an executable install.sh.
mapfile -t all_tools < <(
  for d in "${here}"/*/; do
    [[ -f "${d}install.sh" ]] && basename "${d}"
  done | sort
)

tools=("$@")
[[ ${#tools[@]} -eq 0 ]] && tools=("${all_tools[@]}")

for tool in "${tools[@]}"; do
  dir="${here}/${tool}"
  if [[ ! -f "${dir}/install.sh" ]]; then
    echo "skip: no such tool '${tool}' (have: ${all_tools[*]})" >&2
    continue
  fi
  echo "==> ${tool}"
  bash "${dir}/install.sh"
  echo
done

echo "All done."
