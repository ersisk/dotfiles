#!/usr/bin/env bash
# window-name-refresh — triggers automatic renaming when the pane command changes.
#
# In tmux 3.7 the #() job inside automatic-rename-format does not re-run when
# pane_current_command changes; the first result (usually "fish") stays cached.
# Toggling automatic-rename off/on resets that cache — which is what happens here.
#
# Runs as often as status-interval; only touches windows whose command changed.

set -uo pipefail

# @wn_last_cmd comes from the format too: one list-windows call instead of a
# separate show-option per window. With no changed window, no tmux command runs.
while IFS='|' read -r target auto cmd last; do
  [[ "$auto" == "1" && -n "$cmd" && "$last" != "$cmd" ]] || continue
  tmux set-option -w -t "$target" @wn_last_cmd "$cmd" 2>/dev/null
  # off/on: drops the #() cache so the format re-runs with the new command
  tmux set-option -w -t "$target" automatic-rename off 2>/dev/null
  tmux set-option -w -t "$target" automatic-rename on 2>/dev/null
done < <(tmux list-windows -a -F '#{session_name}:#{window_index}|#{automatic-rename}|#{pane_current_command}|#{@wn_last_cmd}' 2>/dev/null)
