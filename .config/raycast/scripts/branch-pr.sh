#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Branch PR
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🔀
# @raycast.description Open the GitHub PR of the branch in the active tmux pane.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"

dir=$(tmux -S "$SOCKET" display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || { echo "no active tmux pane"; exit 0; }
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) \
  || { echo "not a git repo: ${dir/#$HOME/~}"; exit 0; }

# gh resolves the PR from the branch's upstream, so it must run inside the repo.
if (cd "$dir" && gh pr view --web >/dev/null 2>&1); then
  echo "→ $branch"
else
  echo "no PR for $branch"
fi
