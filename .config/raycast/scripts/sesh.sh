#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Sesh Session
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🗂
# @raycast.description Raise kitty and switch to the matching sesh session.
# @raycast.argument1 { "type": "text", "placeholder": "session", "optional": true }

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"
JUMP="${CLAUDE_JUMP:-$HOME/.local/bin/claude-jump}"
query="${1:-}"

# A call with no argument goes to the last used session: the sesh list is already
# ordered by last use, but the first entry may be the one currently attached, so
# tmux's own "last session" record is the better answer.
if [[ -z "$query" ]]; then
  target=$(tmux -S "$SOCKET" display-message -p '#{client_last_session}' 2>/dev/null)
else
  # Exact match first, then fuzzy via fzf: "dot" -> "🧩 Dotfiles"
  target=$(sesh list 2>/dev/null | rg -Fx "$query" | head -1)
  [[ -n "$target" ]] || target=$(sesh list 2>/dev/null | fzf --filter="$query" 2>/dev/null | head -1)
fi
[[ -n "$target" ]] || { echo "no matching session: ${query:-<last>}"; exit 0; }

# If the session does not exist yet sesh creates it; with no attached tty it comes
# up detached, and switch-client moves to it afterwards.
if ! tmux -S "$SOCKET" has-session -t "$target" 2>/dev/null; then
  sesh connect --switch "$target" >/dev/null 2>&1 \
    || tmux -S "$SOCKET" new-session -d -s "$target" 2>/dev/null
fi

# No window/pane is passed: only the session is switched to, the rest is the last
# position tmux remembers. Raising lives in claude-jump, aerospace race and all.
"$JUMP" "$SOCKET" "$target" "" ""
echo "→ $target"
