#!/usr/bin/env bash
# git-status — the git branch of the active pane, for the status bar.
#
# Called from @minimal-tmux-status-right, so it runs as often as status-interval.
# It asks tmux for the directory instead of taking an argument: #{...} formats
# inside #() are not expanded by tmux, the command line reaches the shell raw.
# With no git repo it prints nothing. On a detached HEAD it shows the short sha.

set -uo pipefail

MAXLEN=20

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0

# A single rev-parse call gives both the repo check and the branch name
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[[ -n "$branch" ]] || exit 0

if [[ "$branch" == "HEAD" ]]; then
  branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null) || exit 0
fi

# Shorten long branches: a Jira ID alone is enough (feature/GD-536-... -> GD-536).
# The regex looks for letters-dash-digits, not bare digits; revert-1090-feat/GR-1342-... -> GR-1342.
if [[ "$branch" =~ ([A-Z][A-Z0-9]+-[0-9]+) ]]; then
  branch="${BASH_REMATCH[1]}"
elif [[ "$branch" =~ ^(agent)/([0-9a-f]{8}) ]]; then
  branch="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
else
  branch="${branch##*/}"
  ((${#branch} > MAXLEN)) && branch="${branch:0:MAXLEN}.."
fi

printf '#[fg=#98BB6C] \uf418 %s' "$branch"
