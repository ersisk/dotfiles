#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Shortcut Panel
# @raycast.mode silent
# @raycast.packageName Tools
# @raycast.icon ⌨️
# @raycast.description Raise kitty and open the shortcut panel in a tmux popup.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"
JUMP="${CLAUDE_JUMP:-$HOME/.local/bin/claude-jump}"
PANEL="$HOME/.config/tmux/keys-panel.sh"

# The panel is a tmux popup, so a client is required. Opening a new kitty window
# was possible too; aerospace tiles that into the workspace you are on, which
# visually knocked the panel out of place.
client=$(tmux -S "$SOCKET" list-clients -F '#{client_name}' 2>/dev/null | head -1)
[[ -n "$client" ]] || { echo "no tmux client"; exit 0; }

# Empty session: claude-jump just raises kitty and exits. Raising is solved there
# (aerospace race included), so it is not solved a second time here.
"$JUMP" "$SOCKET" "" "" ""

# Without -E it blocks until the popup closes and Raycast sits on its spinner, so
# it is backgrounded. KEYS_PANEL_POPUP skips the panel's own popup wrapper.
tmux -S "$SOCKET" display-popup -c "$client" -E -w 88% -h 80% \
    "KEYS_PANEL_POPUP=1 '$PANEL'" &
