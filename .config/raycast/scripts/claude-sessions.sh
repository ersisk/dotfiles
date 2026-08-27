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

. "${CLAUDE_STATE_LIB:-$HOME/.local/share/claude-menubar/claude-state.sh}"

rows=$(emit_rows)
if [[ -z "$rows" ]]; then
  echo "No Claude session running."
  exit 0
fi

printf '%s\n' "$rows" | while IFS=$'\t' read -r _ state project age sess win _ _ detail; do
  printf '%s  %-13s %-16s %s:%s  (%s)\n' \
    "$(state_icon "$state")" "$(state_label "$state")" "$project" "$sess" "$win" "$age"
  [[ -n "$detail" ]] && printf '      %s\n' "$detail"
done
