#!/usr/bin/env bash

list_claude_panes() {
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_tty}|#{pane_current_path}' |
  while IFS='|' read -r target tty path; do
    # o pane'in tty'sinde claude çalışıyor mu?
    if ps -o args= -t "${tty#/dev/}" 2>/dev/null | grep -q '[c]laude'; then
      printf '%s\t %s\n' "$target" "${path/#$HOME/~}"
    fi
  done
}

selected=$(list_claude_panes | fzf-tmux -p 100%,100% --reverse --ansi \
  --border-label ' claude sessions ' --prompt '🤖 ' \
  --header 'açık claude oturumları' \
  --delimiter '\t' \
  --preview 'tmux capture-pane -pe -t {1} | tail -n 50' \
  --preview-window 'right:70%')

[ -z "$selected" ] && exit 0

target=$(printf '%s' "$selected" | cut -f1)

tmux switch-client -t "${target%%:*}"
tmux select-window -t "${target%.*}"
tmux select-pane -t "$target"
