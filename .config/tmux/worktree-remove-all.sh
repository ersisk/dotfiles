#!/usr/bin/env bash
# worktree-remove-all — deletes every cleanable worktree after a single confirmation.
#
# Called with ctrl-alt-d in the panel. It knows NONE of the criteria itself: it
# calls worktree-remove.sh with WT_BATCH=1 for each worktree, so the rules live in
# one place instead of panel/single-delete/bulk-delete being three sources of truth.
#
# Anything undeletable is refused anyway, so "all" and "the cleanable ones" are the
# same set: no selection marking (Tab) is needed.
#
# PR state is queried again for every worktree (gh, serially). The panel cache is
# not used, because fresh verification at delete time is the point of this design.

set -uo pipefail

dir="${1:-}"
[[ -n "$dir" && -d "$dir" ]] || { echo "Invalid path."; sleep 2; exit 1; }

REMOVE="$HOME/.config/tmux/worktree-remove.sh"
[[ -x "$REMOVE" ]] || { echo "worktree-remove.sh not found: $REMOVE"; sleep 2; exit 1; }

main_wt=$(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)

# The main worktree is dropped from the list: it cannot be deleted and only inflates the count.
paths=()
while IFS= read -r line; do
  p="${line#worktree }"
  [[ "$p" == "$main_wt" ]] && continue
  paths+=("$p")
done < <(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ')

count=${#paths[@]}
(( count )) || { echo "  No worktrees besides the main one."; sleep 2; exit 0; }

printf '\n  %s worktrees will be scanned.\n' "$count"
printf '  Only ones with a merged PR, a clean tree and everything pushed are deleted;\n'
printf '  the rest are skipped, with the reason.\n\n'
printf '  Continue? (y/n) '
read -rsn1 answer; printf '\n\n'
[[ "$answer" == "y" || "$answer" == "Y" ]] || { echo "  Cancelled."; sleep 1; exit 0; }

removed=0
skipped=0
for p in "${paths[@]}"; do
  printf '  ── %s\n' "$(basename "$p")"
  if WT_BATCH=1 "$REMOVE" "$p"; then
    removed=$((removed + 1))
  else
    skipped=$((skipped + 1))
  fi
done

printf '\n  %s deleted, %s skipped.\n\n' "$removed" "$skipped"
printf '  Press any key to close.'
read -rsn1 _
