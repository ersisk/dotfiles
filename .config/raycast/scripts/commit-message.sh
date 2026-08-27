#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Commit Message
# @raycast.mode compact
# @raycast.packageName Claude
# @raycast.icon 📝
# @raycast.description Copy the staged diff and hand it to the Commit Message AI command.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"

# The repo is whichever one the active tmux pane sits in — there is no other cwd
# to inherit when the hotkey is pressed from Slack or a browser.
cwd=$(tmux -S "$SOCKET" display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -n "$cwd" ]] || { echo "No tmux pane to take a repo from." >&2; exit 1; }

repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) \
  || { echo "Not a git repo: $cwd" >&2; exit 1; }

diff=$(git -C "$repo" diff --staged)
[[ -n "$diff" ]] || { echo "Nothing staged in $(basename "$repo")."; exit 0; }

printf '%s' "$diff" | pbcopy
open "raycast://ai-commands/commit-message"
echo "$(basename "$repo") — $(git -C "$repo" diff --staged --shortstat | sed 's/^ *//')"
