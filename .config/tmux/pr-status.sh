#!/usr/bin/env bash
# pr-status — summarises the PR for the active pane's branch in a popup.
#
# Called with prefix+i. It uses gh's existing auth, no extra credentials needed.
# With no PR, a non-git repo or gh missing, it exits with a short message.

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  PR #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
cd "$dir" 2>/dev/null || exit 0

command -v gh >/dev/null || { msg "gh is not installed"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { msg "not a git repo"; exit 0; }

json=$(gh pr view --json number,title,state,isDraft,statusCheckRollup,reviewDecision,url 2>/dev/null)
[[ -n "$json" ]] || { msg "no PR for this branch"; exit 0; }

summary=$(printf '%s' "$json" | python3 ~/.config/tmux/pr-status.py 2>/dev/null)
[[ -n "$summary" ]] || { msg "could not read PR info"; exit 0; }

# Write the summary to a temp file to avoid quote escaping on the popup command line
tmp=$(mktemp -t pr-status) || exit 0
printf '%s\n\n(press any key to close)\n' "$summary" >"$tmp"
# the popup command runs in tmux's default-shell (fish); call bash explicitly for bash syntax
tmux display-popup -E -w 64 -h 12 -T ' PR ' \
  "bash -c \"cat '$tmp'; read -rsn1; rm -f '$tmp'\""
