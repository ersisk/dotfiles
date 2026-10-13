#!/usr/bin/env bash
# agent-panel — left sidebar listing the agent sessions agent-menubar knows about.
#
# No argument (prefix+C, ⌘+⇧+A): opens the panel in the current window, focuses it
# if it is open elsewhere in the window, closes it if it already has focus. Panes
# belong to a window, so the panel stays in the window it was opened in.
# The list is re-read every 2s through fzf's --listen socket; --id-nth keeps the
# cursor on the same session across reloads. Enter jumps and leaves the panel open.

set -uo pipefail

self="${BASH_SOURCE[0]}"
WIDTH=52

. "${AGENT_STATE_LIB:-$HOME/.local/share/agent-menubar/agent-state.sh}"

# Same rows as the menu bar: recovered placeholders are hidden once the session's
# own state file exists, and sessions outside tmux are listed too.
# Each item is two lines, NUL-terminated (fzf --read0). The location comes from tmux,
# not the state file: the recorded window index goes stale when windows renumber.
list() {
  local f line pane id now s w p n
  local -a lines=()
  local -A real=() loc=()
  now=$(date +%s)
  while IFS="$AGENT_ROW_SEP" read -r id s w p n; do
    loc[$id]="$s:$w.$p  $n"
  done < <(tmux list-panes -a -F "#{pane_id}${AGENT_ROW_SEP}#{session_name}${AGENT_ROW_SEP}#{window_index}${AGENT_ROW_SEP}#{pane_index}${AGENT_ROW_SEP}#{window_name}" 2>/dev/null)
  for f in "$STATE_DIR"/*.json; do
    [[ -r "$f" ]] || continue
    line=$(< "$f")
    lines+=("$line")
    if [[ "$line" != *'"recovered":true'* ]]; then
      pane=$(json_field "$line" tmux_pane)
      [[ -n "$pane" ]] && real[$pane]=1
    fi
  done
  (( ${#lines[@]} )) || return 0

  for line in "${lines[@]}"; do
    pane=$(json_field "$line" tmux_pane)
    [[ "$line" == *'"recovered":true'* && -n "${real[$pane]:-}" ]] && continue
    local state agent updated
    state=$(json_field "$line" state)
    agent=$(json_field "$line" agent)
    updated=$(json_num "$line" updated_at)
    id=${pane:-none}
    [[ -n "$pane" ]] || agent="${agent:-claude}·ext"
    printf '%s\t%s\t%s\t%s %-14.14s %-9s %4s  %s\t%s\n' \
      "$(state_prio "$state")" "${updated:-0}" "$id" \
      "$(state_icon "$state")" "$(json_field "$line" project)" "${agent:-claude}" \
      "$(short_age "$updated" "$now")" "$(json_field "$line" detail)" \
      "${loc[$id]:-${pane:+gone}}"
  done | sort -t$'\t' -k1,1n -k2,2nr |
    awk -F'\t' '{ printf "%s\t%s\n   \033[2m%s\033[0m%c", $3, $4, ($5 == "" ? "not in tmux" : $5), 0 }'
}

jump() {
  local pane="$1" session
  if [[ "$pane" == none ]]; then
    tmux display-message -d 1500 "not in tmux"
    return 0
  fi
  session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null) || return 0
  tmux switch-client -t "$session"
  tmux select-window -t "$pane"
  tmux select-pane -t "$pane"
}

run() {
  local sock="${TMPDIR:-/tmp}/agent-panel-$$.sock" loop
  (
    while sleep 2; do
      curl -sf --unix-socket "$sock" -X POST http://localhost \
        -d "reload-sync('$self' list)" >/dev/null 2>&1 || [[ -S "$sock" ]] || exit 0
    done
  ) &
  loop=$!
  trap 'kill "$loop" 2>/dev/null; rm -f "$sock"' EXIT

  list | fzf --listen="$sock" --read0 \
    --ansi --reverse --no-sort --track --id-nth=1 \
    --delimiter='\t' --with-nth=2 \
    --border=right --border-label=' Agents ' --prompt='󰘦 ' \
    --header='enter: jump   esc: close' \
    --bind "enter:execute-silent('$self' jump {1})" \
    --no-preview
}

toggle() {
  local panel active
  # @agent_panel last: it is empty on every other pane and awk collapses the gap.
  read -r panel active < <(tmux list-panes -F '#{pane_id} #{pane_active} #{@agent_panel}' |
    awk '$3 == 1 { print $1, $2; exit }')
  if [[ -n "$panel" ]]; then
    if [[ "$active" == 1 ]]; then
      tmux kill-pane -t "$panel"
    else
      tmux select-pane -t "$panel"
    fi
    return 0
  fi
  panel=$(tmux split-window -hbf -l "$WIDTH" -P -F '#{pane_id}' "'$self' run") || return 0
  tmux set-option -p -t "$panel" @agent_panel 1
}

case "${1:-}" in
  list) list ;;
  jump) jump "${2:-}" ;;
  run) run ;;
  *) toggle ;;
esac
