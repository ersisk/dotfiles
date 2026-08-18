#!/usr/bin/env bash
# claude-status — status bar'da dikkat bekleyen Claude pane sayısı.
#
# @minimal-tmux-status-right-extra ile çağrılır, status-interval kadar sık koşar.
# Glyph listesi claude-next.sh ile aynı tutulmalı: 🔨/⏳ (çalışıyor) sayılmaz.
# Bekleyen yoksa hiçbir şey yazmaz — status bar sessiz kalsın.

set -uo pipefail

ATTENTION_GLYPHS='👀✅🏁'

cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

count=0
first=""
while read -r sess widx glyph; do
  [[ -n "$glyph" && "$ATTENTION_GLYPHS" == *"$glyph"* ]] || continue
  count=$((count + 1))
  if [[ -z "$first" ]]; then
    # Aynı session'daysa sadece pencere no; başka session'daysa session:pencere
    if [[ "$sess" == "$cur_session" ]]; then
      first="$widx"
    else
      first="$sess:$widx"
    fi
  fi
done < <(tmux list-windows -a -F '#{session_name} #{window_index} #{@claude_state}' 2>/dev/null)

((count == 0)) && exit 0

if ((count == 1)); then
  label="$first"
else
  label="$first +$((count - 1))"
fi

# Baştaki boşluk #S'den ayırır (plugin ikisini boşluksuz birleştiriyor).
printf ' #[fg=#16161d,bg=#e6c384,bold] 󰘦 %s #[default]' "$label"
