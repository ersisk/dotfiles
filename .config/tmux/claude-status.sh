#!/usr/bin/env bash
# claude-status — status bar'da dikkat bekleyen Claude pane sayısı.
#
# @minimal-tmux-status-right-extra ile çağrılır, status-interval kadar sık koşar.
# Glyph listesi claude-next.sh ile aynı tutulmalı: 󰓦/󱎫 (çalışıyor) sayılmaz.
# Bekleyen yoksa hiçbir şey yazmaz — status bar sessiz kalsın.

set -uo pipefail

ATTENTION_GLYPHS='󰛐'

cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

count=0
first=""
first_glyph=""
first_local=""
first_local_glyph=""
while read -r sess widx glyph; do
  [[ -n "$glyph" && "$ATTENTION_GLYPHS" == *"$glyph"* ]] || continue
  count=$((count + 1))
  if [[ "$sess" == "$cur_session" ]]; then
    # Aynı session: sadece pencere no yeter, önceliklidir
    [[ -z "$first_local" ]] && { first_local="$widx"; first_local_glyph="$glyph"; }
  else
    [[ -z "$first" ]] && { first="$sess:$widx"; first_glyph="$glyph"; }
  fi
done < <(tmux list-windows -a -F '#{session_name} #{window_index} #{@claude_state}' 2>/dev/null)

# Kendi session'ındaki bekleyen varsa onu göster
[[ -n "$first_local" ]] && { first="$first_local"; first_glyph="$first_local_glyph"; }

((count == 0)) && exit 0

if ((count == 1)); then
  label="$first"
else
  label="$first +$((count - 1))"
fi

# Renk ilk bekleyenin durumuna gore; palet claude-tmux-notify ile ayni.
case "$first_glyph" in
  '󰛐') bg='#ff9e3b' ;;  # cevap bekliyor  - roninYellow
  '') bg='#98bb6c' ;;  # bitti           - springGreen
  '') bg='#7e9cd8' ;;  # arka plan bitti - crystalBlue
  *) bg='#e6c384' ;;
esac

# Bastaki bosluk soldaki segmentten ayirir (plugin ikisini bosluksuz birlestiriyor).
printf ' #[fg=%s]#[fg=#16161d,bg=%s,bold] 󱜙 %s #[default]' "$bg" "$bg" "$label"
