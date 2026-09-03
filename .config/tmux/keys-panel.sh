#!/usr/bin/env bash
# keys-panel — shows the kitty + tmux + aerospace + Raycast shortcuts in a
# searchable list.
#
# The source is the config files themselves (see keys-panel.py), no separate
# cheatsheet is kept. Enter copies the keys of the selected row to the clipboard.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/keys-panel.py"

if [[ ! -f "$PARSER" ]]; then
    echo "keys-panel.py not found: $PARSER" >&2
    exit 1
fi

rows="$(python3 "$PARSER")"
if [[ -z "$rows" ]]; then
    echo "no shortcuts found" >&2
    exit 1
fi

# inside tmux use a popup, otherwise run directly
if [[ -n "${TMUX:-}" && "${KEYS_PANEL_POPUP:-}" != "1" ]]; then
    exec tmux display-popup -w 88% -h 80% -E \
        "KEYS_PANEL_POPUP=1 '${BASH_SOURCE[0]}'"
fi

selection="$(printf '%s\n' "$rows" | fzf \
    --prompt='shortcut > ' \
    --header='Enter: copy keys · Esc: close' \
    --header-first \
    --layout=reverse \
    --info=inline \
    --border=rounded \
    --border-label=' Shortcuts (kitty · tmux · aerospace · raycast) ' \
    --ansi \
    --no-multi \
    --pointer='▶' \
    --color='label:bold' \
    --preview-window=hidden \
    || true)"

[[ -z "$selection" ]] && exit 0

# the first two columns are the keys; drop the description and copy only those
# fzf --ansi returns the selection raw; keep color codes out of the clipboard
selection="$(printf '%s' "$selection" | sed $'s/\033\[[0-9;]*m//g')"
keys="$(printf '%s' "$selection" | awk -F'  +' '{
    out = $1
    if ($2 ~ /\^a/) out = out "  /  " $2
    print out
}')"

if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$keys" | pbcopy
    [[ -n "${TMUX:-}" ]] && tmux display-message -d 1500 "copied: $keys"
fi
