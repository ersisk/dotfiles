#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Claude Sessions
# @raycast.mode fullOutput
# @raycast.packageName Claude
# @raycast.icon 🤖
# @raycast.description Every running Claude Code session, most urgent first.

# Raycast starts scripts with a bare PATH; tmux and friends live in the brew prefix.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

. "${AGENT_STATE_LIB:-$HOME/.local/share/agent-menubar/agent-state.sh}"

rows=$(emit_rows)
if [[ -z "$rows" ]]; then
  echo "No Claude session running."
  exit 0
fi

printf '%s\n' "$rows" | while IFS=$'\t' read -r _ state project agent age sess win _ _ detail; do
  printf '%s  %-13s %-16s %-9s %s:%s  (%s)\n' \
    "$(state_icon "$state")" "$(state_label "$state")" "$project" "$agent" "$sess" "$win" "$age"
  [[ -n "$detail" ]] && printf '      %s\n' "$detail"
done
