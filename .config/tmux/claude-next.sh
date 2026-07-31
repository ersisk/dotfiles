#!/usr/bin/env bash
# claude-next — jump to the next Claude pane that wants attention.
#
# Bound to prefix + j. Cycles through windows whose @claude_state (set by
# claude-tmux-notify) is one of the "needs you" glyphs, in a stable global order,
# always landing on the one after the current window so repeated presses advance.
#
# Working states (🔨 busy, ⏳ background running) are deliberately excluded —
# Claude is still going, there is nothing to answer yet.

set -uo pipefail

ATTENTION_GLYPHS='👀✅🏁'

# session:window for every window flagged with an attention glyph, sorted so the
# cycle order is stable across invocations regardless of tmux's listing order.
mapfile -t targets < <(
  tmux list-windows -a -F '#{session_name}:#{window_index} #{@claude_state}' 2>/dev/null |
  while read -r target glyph; do
    [[ -n "$glyph" && "$ATTENTION_GLYPHS" == *"$glyph"* ]] && printf '%s\n' "$target"
  done | sort
)

if (( ${#targets[@]} == 0 )); then
  tmux display-message -d 1500 "#[fg=#16161d,bg=#7e9cd8,bold] 󰘦  CLAUDE #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] no pane waiting "
  exit 0
fi

current=$(tmux display-message -p '#{session_name}:#{window_index}' 2>/dev/null)

# Pick the first target after the current window; wrap to the first otherwise.
next="${targets[0]}"
for i in "${!targets[@]}"; do
  if [[ "${targets[i]}" == "$current" ]]; then
    next="${targets[(i + 1) % ${#targets[@]}]}"
    break
  fi
done

session="${next%%:*}"
tmux switch-client -t "$session" 2>/dev/null
tmux select-window -t "$next" 2>/dev/null

# Focus the pane actually running Claude; a window can hold several panes.
pane=$(
  tmux list-panes -t "$next" -F '#{pane_index} #{pane_tty}' 2>/dev/null |
  while read -r idx tty; do
    if ps -o args= -t "${tty#/dev/}" 2>/dev/null | grep -q '[c]laude'; then
      printf '%s\n' "$idx"
      break
    fi
  done
)
[[ -n "$pane" ]] && tmux select-pane -t "${next}.${pane}" 2>/dev/null

exit 0
