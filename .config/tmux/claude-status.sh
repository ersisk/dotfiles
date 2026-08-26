#!/usr/bin/env bash
# claude-status — status bar'da dikkat bekleyen Claude pane sayısı.
#
# @minimal-tmux-status-right-extra ile çağrılır, status-interval kadar sık koşar
# (3 s), bu yüzden ek process yok: claude-menubar state dosyaları tek satırlık JSON
# ve bash regex ile okunuyor.
# Bekleyen yoksa hiçbir şey yazmaz — status bar sessiz kalsın.

set -uo pipefail

STATE_DIR="${CLAUDE_MENUBAR_STATE_DIR:-$HOME/.local/state/claude-menubar/sessions}"

# Tek satirlik JSON'dan tek alan cikarir. Bastaki virgul sart: detail icindeki bir
# alinti isareti sahte anahtar eslesmesi uretmesin.
json_field() {
  local re=",\"$2\":\"([^\"]*)\""
  [[ "$1" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# Dikkat bekleyen her oturum icin: session, pencere, pane, durum, son mesaj.
# Onceki oncelik alanina gore siralanir, sonra atilir: cevap bekleyen once gelsin -
# status bar rengi ve prefix+j'nin ilk duragi en acil olani gostersin. Ayni oncelikte
# session adina gore, boylece sira cagrilar arasinda sabit.
# Her zaman process substitution icinde calisir, glob'suz dizin sorun degil.
emit_rows() {
  local f line state sess prio
  for f in "$STATE_DIR"/*.json; do
    [[ -r "$f" ]] || continue
    line=$(< "$f")
    state=$(json_field "$line" state)
    case "$state" in
      waiting) prio=0 ;;
      done-bg) prio=1 ;;
      done) prio=2 ;;
      *) continue ;;
    esac
    sess=$(json_field "$line" tmux_session)
    [[ -n "$sess" ]] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$prio" "$sess" "$(json_field "$line" tmux_window)" \
      "$(json_field "$line" tmux_pane)" "$state" "$(json_field "$line" detail)"
  done | sort | cut -f2-
}

cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

count=0
first=""
first_state=""
first_local=""
first_local_state=""
while IFS=$'\t' read -r sess widx _ state _; do
  count=$((count + 1))
  if [[ "$sess" == "$cur_session" ]]; then
    # Aynı session: sadece pencere no yeter, önceliklidir
    [[ -z "$first_local" ]] && { first_local="$widx"; first_local_state="$state"; }
  else
    [[ -z "$first" ]] && { first="$sess:$widx"; first_state="$state"; }
  fi
done < <(emit_rows)

# Kendi session'ındaki bekleyen varsa onu göster
[[ -n "$first_local" ]] && { first="$first_local"; first_state="$first_local_state"; }

((count == 0)) && exit 0

if ((count == 1)); then
  label="$first"
else
  label="$first +$((count - 1))"
fi

# Renk ilk bekleyenin durumuna gore; palet claude-tmux-notify ile ayni.
case "$first_state" in
  waiting) bg='#ff9e3b' ;;  # cevap bekliyor  - roninYellow
  done) bg='#98bb6c' ;;     # bitti           - springGreen
  done-bg) bg='#7e9cd8' ;;  # arka plan bitti - crystalBlue
  *) bg='#e6c384' ;;
esac

# Bastaki bosluk soldaki segmentten ayirir (plugin ikisini bosluksuz birlestiriyor).
printf ' #[fg=%s]#[fg=#16161d,bg=%s,bold] 󱜙 %s #[default]' "$bg" "$bg" "$label"
