#!/usr/bin/env bash
# pr-status — aktif pane'in branch'ine ait PR durumunu popup'ta ozetler.
#
# prefix+i ile cagrilir. gh'in mevcut yetkisini kullanir, ek kimlik gerekmez.
# PR yoksa, repo git degilse veya gh kurulu degilse kisa bir mesajla ciker.

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  PR #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
cd "$dir" 2>/dev/null || exit 0

command -v gh >/dev/null || { msg "gh kurulu degil"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { msg "git repo degil"; exit 0; }

json=$(gh pr view --json number,title,state,isDraft,statusCheckRollup,reviewDecision,url 2>/dev/null)
[[ -n "$json" ]] || { msg "bu branch icin PR yok"; exit 0; }

summary=$(printf '%s' "$json" | python3 ~/.config/tmux/pr-status.py 2>/dev/null)
[[ -n "$summary" ]] || { msg "PR bilgisi okunamadi"; exit 0; }

# Ozeti gecici dosyaya yaz: popup komut satirinda tirnak kacisiyla ugrasmamak icin
tmp=$(mktemp -t pr-status) || exit 0
printf '%s\n\n(kapatmak icin bir tusa bas)\n' "$summary" >"$tmp"
tmux display-popup -E -w 64 -h 12 -T ' PR ' \
  "cat '$tmp'; read -rsn1; rm -f '$tmp'"
