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
# pane id and the last message, so neither the per-pane ps scan nor the show-option
# round trips are needed any more.

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

# Durum -> glyph; claude-tmux-notify'daki set_window_state ile ayni kalmali.
glyph_for() {
  case "$1" in
    waiting) printf '%s' '󰛐' ;;
    done) printf '%s' '' ;;
    done-bg) printf '%s' '' ;;
  esac
}

mapfile -t rows < <(emit_rows)

if (( ${#rows[@]} == 0 )); then
  tmux display-message -d 1500 "#[fg=#16161d,bg=#7e9cd8,bold] 󰘦  CLAUDE #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] no pane waiting "
  exit 0
fi

targets=()
for row in "${rows[@]}"; do
  IFS=$'\t' read -r sess widx _ _ _ <<< "$row"
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

IFS=$'\t' read -r _ _ pane state detail <<< "${rows[idx]}"
target="${targets[idx]}"

tmux switch-client -t "${target%%:*}" 2>/dev/null
tmux select-window -t "$target" 2>/dev/null
# Pane id kayittan gelir: pencerede birden fazla pane olsa da dogru olana gidilir.
[[ -n "$pane" ]] && tmux select-pane -t "$pane" 2>/dev/null

# Gecilen pane'in son mesajini kisa bir mesaj cubugunda goster: hangi cevabi
# bekledigini pane'e bakmadan anlamak icin.
if [[ -n "$detail" ]]; then
  tmux display-message -d 2500 "#[fg=#16161d,bg=#7e9cd8,bold] $(glyph_for "$state") ${target} #[fg=#7e9cd8,bg=#1f1f28,nobold]#[fg=#dcd7ba,bg=#1f1f28] ${detail} "
fi

exit 0
