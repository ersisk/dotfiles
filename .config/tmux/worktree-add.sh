#!/usr/bin/env bash
# worktree-add — creates a new worktree and attaches to it with sesh.
#
# Called with prefix+N. The branch name is typed at the fzf prompt; a name in the
# clipboard in jira-to-branch output format arrives pre-filled.
# Picking an existing branch attaches to it, typing a new name creates the branch.
# The directory is created as a sibling of the main worktree: <parent>/<slug>

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  WT #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { msg "not a git repo"; exit 0; }

# Worktrees become siblings of the main working tree, never nested inside it
main_wt=$(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)
[[ -n "$main_wt" ]] || { msg "main worktree not found"; exit 0; }
parent=$(dirname "$main_wt")

# Pre-fill from the clipboard when it is in jira-to-branch format; ignore it otherwise
clip=$(pbpaste 2>/dev/null | head -1 | tr -d '\r\n')
[[ "$clip" =~ ^[A-Za-z0-9._/-]{3,80}$ ]] || clip=""

# Existing remote/local branches are offered as options; a newly typed name is accepted too
# fzf --print-query output: 1=query, 2=expect key, 3=selection (no third line without one).
# Take line 3 when picked from the list, the query when a new name was typed.
raw=$(
  git -C "$dir" for-each-ref --sort=-committerdate --count=200 \
    --format='%(refname:short)' refs/heads refs/remotes/origin 2>/dev/null \
    | sed 's|^origin/||' | rg -v '^(HEAD|origin)$' | awk '!seen[$0]++' \
    | fzf-tmux -p 80%,60% \
        --reverse --border rounded --border-label ' New Worktree ' \
        --prompt 'branch: ' --query "$clip" \
        --header 'enter: create/attach   esc: cancel   (you can type a new name)' \
        --print-query --expect=enter
) || exit 0

branch=$(printf '%s\n' "$raw" | sed -n '3p')
[[ -n "$branch" ]] || branch=$(printf '%s\n' "$raw" | sed -n '1p')
branch=$(printf '%s' "$branch" | tr -d '\r\n' | sed 's|^[[:space:]]*||; s|[[:space:]]*$||')
[[ -n "$branch" ]] || exit 0

# Already open in a worktree? Then switch to it instead of creating another
existing=$(git -C "$dir" worktree list --porcelain 2>/dev/null \
  | awk -v b="refs/heads/$branch" '/^worktree /{p=$2} /^branch /{if ($2==b) print p}' | head -1)
if [[ -n "$existing" && -d "$existing" ]]; then
  msg "already exists, attaching: $branch"
  command -v sesh >/dev/null && sesh connect --switch "$existing" 2>/dev/null \
    || tmux new-window -c "$existing"
  exit 0
fi

# The directory name is the last part of the branch: feature/GD-956-x -> GD-956-x
slug=$(basename "$branch")
target="$parent/$slug"
[[ -e "$target" ]] && { msg "directory already exists: $slug"; exit 0; }

# Attach to the branch if it exists remotely/locally, else create it from the base.
# --force is never passed; git's own protection stays in place.
if git -C "$dir" show-ref --verify --quiet "refs/heads/$branch"; then
  out=$(git -C "$dir" worktree add "$target" "$branch" 2>&1)
elif git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  out=$(git -C "$dir" worktree add --track -b "$branch" "$target" "origin/$branch" 2>&1)
else
  base=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  base=${base:-master}
  git -C "$dir" fetch --quiet origin "$base" 2>/dev/null
  out=$(git -C "$dir" worktree add -b "$branch" "$target" "origin/$base" 2>&1)
fi

if [[ ! -d "$target" ]]; then
  msg "could not create: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

# The panel caches PR states; drop it so the new worktree shows up right away
rm -f "${TMPDIR:-/tmp}/worktree-panel-pr.json" 2>/dev/null

msg "created: $slug"
command -v sesh >/dev/null && sesh connect --switch "$target" 2>/dev/null \
  || tmux new-window -c "$target"
