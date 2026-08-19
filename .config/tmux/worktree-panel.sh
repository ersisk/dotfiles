#!/usr/bin/env bash
# worktree-panel — aktif repo'nun worktree'lerini durumlariyla listeler.
#
# prefix+W ile cagrilir. Her satirda: branch, calisma agaci durumu, PR durumu,
# son dokunma yasi. PR'i merged + agaci temiz olanlar "temizlenebilir" isaretlenir.
# Enter secilen worktree'ye sesh ile baglanir. Hicbir sey silinmez.

set -uo pipefail

msg() {
  tmux display-message -d 2000 \
    "#[fg=#16161d,bg=#7e9cd8,bold]  WT #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] $1 "
}

dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -d "$dir" ]] || exit 0
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { msg "git repo degil"; exit 0; }

rows=$(python3 ~/.config/tmux/worktree-panel.py "$dir" 2>/dev/null)
[[ -n "$rows" ]] || { msg "worktree bulunamadi"; exit 0; }

# Tek worktree varsa panel acmaya gerek yok
if [[ $(printf '%s\n' "$rows" | wc -l) -le 1 ]]; then
  msg "tek worktree"
  exit 0
fi

# ctrl-d silme scriptini calistirir; o script guvenlik kontrollerini kendi yapar
# ve onay ister. Sonrasinda liste yenilenir ki silinen satir kaybolsun.
selected=$(printf '%s\n' "$rows" | fzf-tmux -p 92%,55% \
  --ansi --reverse --with-nth=2 --delimiter='\t' \
  --border rounded --border-label ' Worktrees ' \
  --header 'enter: bagla   ctrl-d: sil   esc: kapat' \
  --bind "ctrl-d:execute(~/.config/tmux/worktree-remove.sh {1})+reload(python3 ~/.config/tmux/worktree-panel.py '$dir')" \
  --no-preview) || exit 0

[[ -n "$selected" ]] || exit 0
target=$(printf '%s' "$selected" | cut -f1)
[[ -d "$target" ]] || exit 0

command -v sesh >/dev/null && sesh connect --switch "$target" 2>/dev/null \
  || tmux new-window -c "$target"
