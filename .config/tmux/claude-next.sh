#!/usr/bin/env bash
# claude-next — jump to the next Claude pane that wants attention.
#
# Bound to prefix + j. Cycles through the sessions claude-tmux-notify flagged as
# needing attention, in a stable global order, always landing on the one after the
# current window so repeated presses advance.
#
# Working states (working, bg-running) are deliberately excluded — Claude is still
# going, there is nothing to answer yet.
#
# Reads the claude-menubar state files rather than @claude_state window options: one
# file per session instead of one glyph per window, and each file already carries the
# pane id, so neither the per-pane ps scan nor the show-option round trips are needed
# any more.
#
# Nothing is printed after a successful jump: it used to preview the pane's last
# message, which is redundant when the whole point is that you are now looking at that
# pane. The "no pane waiting" message stays — that is the one case where pressing the
# key visibly does nothing.

set -uo pipefail

# Okuyucu paylasilan: ayni JSON sozlesmesini Raycast script'leri de ayristiriyor,
# ucuncu bir kopya tutmanin bedeli yok (olculdu: bos bash 2.2 ms, source'lu 2.0 ms).
. "${CLAUDE_STATE_LIB:-$HOME/.local/share/claude-menubar/claude-state.sh}"

# prio < 3: waiting / done-bg / done. Calisan oturumda cevaplanacak bir sey yok.
mapfile -t rows < <(emit_rows | awk -F'\t' '$1 < 3')

if (( ${#rows[@]} == 0 )); then
  tmux display-message -d 1500 "#[fg=#16161d,bg=#7e9cd8,bold] 󰘦  CLAUDE #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] no pane waiting "
  exit 0
fi

targets=()
for row in "${rows[@]}"; do
  IFS=$'\t' read -r _ _ _ _ sess widx _ <<< "$row"
  targets+=("${sess}:${widx}")
done

current=$(tmux display-message -p '#{session_name}:#{window_index}' 2>/dev/null)

# Pick the first target after the current window; wrap to the first otherwise.
idx=0
for i in "${!targets[@]}"; do
  if [[ "${targets[i]}" == "$current" ]]; then
    idx=$(( (i + 1) % ${#targets[@]} ))
    break
  fi
done

IFS=$'\t' read -r _ _ _ _ _ _ pane _ <<< "${rows[idx]}"
target="${targets[idx]}"

tmux switch-client -t "${target%%:*}" 2>/dev/null
tmux select-window -t "$target" 2>/dev/null
# Pane id kayittan gelir: pencerede birden fazla pane olsa da dogru olana gidilir.
[[ -n "$pane" ]] && tmux select-pane -t "$pane" 2>/dev/null

exit 0
