#!/usr/bin/env bash

# @claude_state: claude-tmux-notify'ın window'a yazdığı durum glyph'i.
# Boşsa (henüz hook tetiklenmemiş / idle) nötr bir işaret gösterilir.
state_label() {
  case "$1" in
    󰓦) printf '󰓦 çalışıyor      ' ;;
    󰛐) printf '󰛐 input bekliyor ' ;;
    󱎫) printf '󱎫 arka plan      ' ;;
    ) printf ' bg bitti       ' ;;
    ) printf ' bitti          ' ;;
    *)  printf '󰤄 boşta          ' ;;
  esac
}

list_claude_panes() {
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_tty}|#{pane_current_path}|#{@claude_state}' |
  while IFS='|' read -r target tty path state; do
    # o pane'in tty'sinde claude çalışıyor mu?
    if ps -o args= -t "${tty#/dev/}" 2>/dev/null | grep -q '[c]laude'; then
      printf '%s\t %s\t %s\n' "$target" "$(state_label "$state")" "$(printf '%s' "$path" | sed "s|^$HOME|~|")"
    fi
  done
}

panes=$(list_claude_panes)
if [ -z "$panes" ]; then
  tmux display-message -d 1500 "#[fg=#16161d,bg=#7e9cd8,bold] 󰘦  CLAUDE #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] no claude pane "
  exit 0
fi

selected=$(printf '%s\n' "$panes" | fzf-tmux -p 60%,50% --reverse --ansi \
  --border rounded --border-label ' Agents ' --prompt '🤖 ' \
  --header 'Agents' \
  --delimiter '\t' \
  --no-preview)

[ -z "$selected" ] && exit 0

target=$(printf '%s' "$selected" | cut -f1)

tmux switch-client -t "${target%%:*}"
tmux select-window -t "${target%.*}"
tmux select-pane -t "$target"
