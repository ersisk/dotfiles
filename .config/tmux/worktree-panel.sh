#!/usr/bin/env bash
# worktree-panel — lists the worktrees of the active repo with their state.
#
# Called with prefix+W. Each row: branch, working tree state, PR state, age since
# last touch. Ones with a merged PR and a clean tree are marked "cleanable".
# Enter attaches to the selected worktree with sesh. Nothing is ever deleted.

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  WT #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { msg "not a git repo"; exit 0; }

# No point opening the panel for a single worktree
if [[ $(git -C "$dir" worktree list --porcelain | grep -c '^worktree ') -le 1 ]]; then
  msg "single worktree"
  exit 0
fi

load="python3 ~/.config/tmux/worktree-panel.py '$dir'"

# The list is filled inside fzf: otherwise nothing appears on screen until the
# panel opens (~2s on a cold cache) and there is no sign the key registered.
# ctrl-d runs the delete script; that script does its own safety checks and asks
# for confirmation. The list reloads afterwards so the deleted row disappears.
# ctrl-alt-d calls the same script for every worktree in turn (see
# worktree-remove-all.sh). No Tab marking: anything undeletable is refused anyway,
# so "all" and "the cleanable ones" are the same set.
selected=$(fzf-tmux -p 92%,55% \
  --ansi --reverse --with-nth=2 --delimiter='\t' \
  --border rounded --border-label ' Worktrees ' \
  --header '⧗ scanning…' \
  --bind "start:reload($load)" \
  --bind "load:change-header(enter: attach   ctrl-o: new window   ctrl-d: delete   ctrl-alt-d: clean all   esc: close)" \
  --bind "ctrl-o:execute-silent(tmux new-window -c {1} -n \"\$(basename {1})\")+abort" \
  --bind "ctrl-d:execute(~/.config/tmux/worktree-remove.sh {1})+reload($load)" \
  --bind "ctrl-alt-d:execute(~/.config/tmux/worktree-remove-all.sh {1})+reload($load)" \
  --no-preview </dev/null) || exit 0

[[ -n "$selected" ]] || exit 0
target=$(printf '%s' "$selected" | cut -f1)
[[ -d "$target" ]] || exit 0

command -v sesh >/dev/null && sesh connect --switch "$target" 2>/dev/null \
  || tmux new-window -c "$target"
