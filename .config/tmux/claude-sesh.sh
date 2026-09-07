#!/usr/bin/env bash

# @agent_state: the state glyph agent-tmux-notify writes onto the window.
# When empty (no hook fired yet / idle) a neutral marker is shown.
state_label() {
  case "$1" in
    󰓦) printf '󰓦 working        ' ;;
    󰛐) printf '󰛐 needs input    ' ;;
    󱎫) printf '󱎫 background     ' ;;
    ) printf ' bg done        ' ;;
    ) printf ' done           ' ;;
    *)  printf '󰤄 idle           ' ;;
  esac
}

# Process names that count as an agent, same list as AgentMenubar.swift's agentComms.
# ps reports either a bare name or an absolute path, hence the basename.
declare -A agent_by_tty
while read -r tty comm; do
  agent_by_tty["$tty"]="$comm"
done < <(ps -ax -o tty=,comm= | awk '$1 != "??" { n = split($2, p, "/"); c = p[n]
  if (c == "claude" || c == "opencode") print $1, c }')

list_agent_panes() {
  (( ${#agent_by_tty[@]} )) || return 0
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_tty}|#{pane_current_path}|#{@agent_state}' |
  while IFS='|' read -r target tty path state; do
    agent="${agent_by_tty[${tty#/dev/}]:-}"
    [ -n "$agent" ] || continue
    printf '%s\t %s\t %-9s %s\n' "$target" "$(state_label "$state")" "$agent" \
      "$(printf '%s' "$path" | sed "s|^$HOME|~|")"
  done
}

panes=$(list_agent_panes)
if [ -z "$panes" ]; then
  tmux display-message -d 1500 "#[fg=#16161d,bg=#7e9cd8,bold] 󰘦  AGENTS #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] no agent pane "
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
