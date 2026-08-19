#!/usr/bin/env bash
# worktree-add — yeni worktree olusturur ve sesh ile baglanir.
#
# prefix+N ile cagrilir. Branch adi fzf prompt'unda yazilir; clipboard'da
# jira-to-branch cikti formatinda bir ad varsa on-dolgu olarak gelir.
# Var olan bir branch secilirse ona baglanir, yeni ad yazilirsa branch olusturulur.
# Dizin ana worktree'nin kardesi olarak acilir: <parent>/<slug>

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  WT #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { msg "git repo degil"; exit 0; }

# Worktree'ler ana calisma agacinin kardesi olur, ic ice gecmesin
main_wt=$(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)
[[ -n "$main_wt" ]] || { msg "ana worktree bulunamadi"; exit 0; }
parent=$(dirname "$main_wt")

# Clipboard jira-to-branch formatindaysa on-dolgu yap; degilse yok say
clip=$(pbpaste 2>/dev/null | head -1 | tr -d '\r\n')
[[ "$clip" =~ ^[A-Za-z0-9._/-]{3,80}$ ]] || clip=""

# Var olan uzak/yerel branch'ler secenek olarak sunulur; yazilan yeni ad da kabul edilir
# fzf --print-query cikti: 1=query, 2=expect tusu, 3=secim (secim yoksa 3. satir yok).
# Listeden secildiyse 3. satiri, yeni ad yazildiysa query'yi al.
raw=$(
  git -C "$dir" for-each-ref --sort=-committerdate --count=200 \
    --format='%(refname:short)' refs/heads refs/remotes/origin 2>/dev/null \
    | sed 's|^origin/||' | rg -v '^(HEAD|origin)$' | awk '!seen[$0]++' \
    | fzf-tmux -p 80%,60% \
        --reverse --border rounded --border-label ' Yeni Worktree ' \
        --prompt 'branch: ' --query "$clip" \
        --header 'enter: olustur/bagla   esc: iptal   (yeni ad yazabilirsin)' \
        --print-query --expect=enter
) || exit 0

branch=$(printf '%s\n' "$raw" | sed -n '3p')
[[ -n "$branch" ]] || branch=$(printf '%s\n' "$raw" | sed -n '1p')
branch=$(printf '%s' "$branch" | tr -d '\r\n' | sed 's|^[[:space:]]*||; s|[[:space:]]*$||')
[[ -n "$branch" ]] || exit 0

# Zaten bir worktree'de acik mi? Oyleyse yenisini yaratmadan ona gec
existing=$(git -C "$dir" worktree list --porcelain 2>/dev/null \
  | awk -v b="refs/heads/$branch" '/^worktree /{p=$2} /^branch /{if ($2==b) print p}' | head -1)
if [[ -n "$existing" && -d "$existing" ]]; then
  msg "zaten var, baglaniyor: $branch"
  command -v sesh >/dev/null && sesh connect --switch "$existing" 2>/dev/null \
    || tmux new-window -c "$existing"
  exit 0
fi

# Dizin adi branch'in son parcasi: feature/GD-956-x -> GD-956-x
slug=$(basename "$branch")
target="$parent/$slug"
[[ -e "$target" ]] && { msg "dizin zaten var: $slug"; exit 0; }

# Branch uzakta/yerelde varsa ona baglan, yoksa base'den yeni olustur.
# --force asla gecilmez; git'in kendi korumasi kalir.
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
  msg "olusturulamadi: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

# Panel PR durumlarini cache'liyor; yeni worktree hemen gorunsun
rm -f "${TMPDIR:-/tmp}/worktree-panel-pr.json" 2>/dev/null

msg "olusturuldu: $slug"
command -v sesh >/dev/null && sesh connect --switch "$target" 2>/dev/null \
  || tmux new-window -c "$target"
