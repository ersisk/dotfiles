#!/usr/bin/env bash
# worktree-remove — deletes the worktree picked in worktree-panel, after confirmation.
#
# Called with ctrl-d in the panel. It does not trust the panel's "cleanable" mark
# and re-runs the safety checks at delete time (panel data may be cached).
# It uses git worktree remove; --force is NEVER passed, git's own protection stays.
#
# Called with WT_BATCH=1 (see worktree-remove-all.sh) it asks for no per-item
# confirmation and skips the reading pauses; the blocking rules are unchanged, and
# the exit code tells the caller which worktree was skipped.

set -uo pipefail

batch="${WT_BATCH:-0}"
# In single-worktree mode messages flash by in the fzf popup, so it has to wait
# long enough to read them; in batch mode the waiting belongs to the caller.
pause() { (( batch )) || sleep "$1"; }

target="${1:-}"
[[ -n "$target" && -d "$target" ]] && exit_ok=1 || { echo "Invalid worktree path."; pause 2; exit 1; }

branch=$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)
name=$(basename "$target")

# The main worktree cannot be deleted (git says "is a main working tree"); filter it first
main_wt=$(git -C "$target" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)
if [[ "$target" == "$main_wt" ]]; then
  printf 'RED: this is the main working tree of the repo, it cannot be deleted.\n'
  pause 3; exit 1
fi

# --- Safety checks: each one blocks the delete ---
if [[ "$branch" == "HEAD" ]]; then
  printf 'RED: detached HEAD (%s)\nWhich branch it is on is unclear, check by hand.\n' "$name"
  pause 3; exit 1
fi

dirty=$(git -C "$target" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if (( dirty > 0 )); then
  printf 'RED: %s has %s uncommitted files.\nCommit or stash them first.\n' "$branch" "$dirty"
  pause 3; exit 1
fi

unpushed=$(git -C "$target" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
if [[ "$unpushed" =~ ^[0-9]+$ ]] && (( unpushed > 0 )); then
  printf 'RED: %s has %s unpushed commits.\n' "$branch" "$unpushed"
  pause 3; exit 1
fi

pr_state=$(gh pr list --head "$branch" --state all --limit 1 --json state --jq '.[0].state' 2>/dev/null)
if [[ "$pr_state" != "MERGED" ]]; then
  printf 'RED: no merged PR for %s (state: %s).\nThe work may not be finished.\n' "$branch" "${pr_state:-no PR}"
  pause 3; exit 1
fi

# --- Confirmation ---
# In batch mode confirmation is taken once up front; it is not asked again here.
if (( ! batch )); then
  printf '\n  %s\n  PR merged, working tree clean, everything pushed.\n\n' "$branch"
  printf '  Delete this worktree? (y/n) '
  read -rsn1 answer; printf '\n\n'
  [[ "$answer" == "y" || "$answer" == "Y" ]] || { echo "  Cancelled."; sleep 1; exit 0; }
fi

# The panel caches PR states; drop it so the reloaded list after a delete is fresh.
# The cache is a separate file per repo (see cache_path in worktree-panel.py) — the
# key is the sha1 of git-common-dir, because one shared file mixed up the PR state
# of repos that had branches with the same name.
wt_ident=$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
wt_hash=$(printf '%s' "$wt_ident" | shasum | cut -c1-12)
rm -f "${TMPDIR:-/tmp}/worktree-panel-pr-${wt_hash}.json" 2>/dev/null

if git -C "$target" worktree remove "$target" 2>/dev/null \
   || git -C "$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)" worktree remove "$target" 2>/dev/null; then
  echo "  Deleted: $name"
else
  echo "  Not deleted - git refused. Check by hand:"
  echo "    git worktree remove '$target'"
  pause 2
  exit 1
fi
pause 2
