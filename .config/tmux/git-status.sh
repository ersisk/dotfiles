#!/usr/bin/env bash
# git-status — status bar için aktif pane'in git branch'i.
#
# @minimal-tmux-status-right'tan çağrılır, status-interval kadar sık koşar.
# Dizini argüman yerine tmux'a sorarak alır: #() içindeki #{...} formatları
# tmux tarafından genişletilmez, komut satırı shell'e düz string gider.
# Git repo yoksa hiçbir şey yazmaz. Detached HEAD'de kısa sha gösterir.

set -uo pipefail

MAXLEN=20

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0

# Tek rev-parse çağrısı hem repo kontrolü hem branch adı verir
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[[ -n "$branch" ]] || exit 0

if [[ "$branch" == "HEAD" ]]; then
  branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null) || exit 0
fi

# Uzun dallari kisalt: Jira ID varsa tek basina yeterli (feature/GD-536-... -> GD-536).
# Regex salt rakami degil harf-tire-rakami arar; revert-1090-feat/GR-1342-... -> GR-1342.
if [[ "$branch" =~ ([A-Z][A-Z0-9]+-[0-9]+) ]]; then
  branch="${BASH_REMATCH[1]}"
elif [[ "$branch" =~ ^(agent)/([0-9a-f]{8}) ]]; then
  branch="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
else
  branch="${branch##*/}"
  ((${#branch} > MAXLEN)) && branch="${branch:0:MAXLEN}.."
fi

printf '#[fg=#98BB6C] \uf418 %s' "$branch"
