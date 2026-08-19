#!/usr/bin/env bash
# window-name-refresh — pane komutu degisince otomatik yeniden adlandirmayi tetikler.
#
# tmux 3.7'de automatic-rename-format icindeki #() job'u pane_current_command
# degistiginde yeniden calismiyor; ilk sonuc (genelde "fish") cache'te kaliyor.
# automatic-rename'i off/on yapmak cache'i sifirliyor — burada yapilan bu.
#
# status-interval kadar sik kosar; sadece komutu degismis pencerelere dokunur.

set -uo pipefail

while IFS='|' read -r target auto cmd; do
  [[ "$auto" == "1" ]] || continue
  [[ -n "$cmd" ]] || continue
  last=$(tmux show-option -wqv -t "$target" @wn_last_cmd 2>/dev/null)
  [[ "$last" == "$cmd" ]] && continue
  tmux set-option -w -t "$target" @wn_last_cmd "$cmd" 2>/dev/null
  # off/on: #() cache'ini dusurur, format yeni komutla yeniden calisir
  tmux set-option -w -t "$target" automatic-rename off 2>/dev/null
  tmux set-option -w -t "$target" automatic-rename on 2>/dev/null
done < <(tmux list-windows -a -F '#{session_name}:#{window_index}|#{automatic-rename}|#{pane_current_command}' 2>/dev/null)
