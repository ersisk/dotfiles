#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Jump to Claude
# @raycast.mode compact
# @raycast.packageName Claude
# @raycast.icon 🔔
# @raycast.description Raise kitty on the Claude session that wants attention.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

. "${AGENT_STATE_LIB:-$HOME/.local/share/agent-menubar/agent-state.sh}"
JUMP="${AGENT_JUMP:-$HOME/.local/bin/agent-jump}"

# Only the states prefix+j stops at: a working session has nothing to answer yet.
rows=$(emit_rows | awk -F'\t' '$1 < 3')
[[ -n "$rows" ]] || { echo "Nothing waiting."; exit 0; }

socket=$(printf '%s\n' "$rows" | head -1 | cut -f9)

# Same cycling as prefix+j: land on the target after the window tmux is currently
# on, so pressing the key again advances instead of re-selecting the same pane.
current=""
[[ -n "$socket" ]] && current=$(tmux -S "$socket" display-message -p '#{session_name}:#{window_index}' 2>/dev/null)

pick=$(printf '%s\n' "$rows" | awk -F'\t' -v cur="$current" '
  { line[NR] = $0; key[NR] = $6 ":" $7 }
  END {
    n = NR; want = 1
    for (i = 1; i <= n; i++) if (key[i] == cur) { want = i % n + 1; break }
    print line[want]
  }')

IFS=$'\t' read -r _ state project agent _ sess win pane socket _ <<< "$pick"
"$JUMP" "$socket" "$sess" "$win" "$pane"
printf '%s %s (%s) → %s:%s (%s)\n' "$(state_icon "$state")" "$project" "$agent" "$sess" "$win" "$(state_label "$state")"
