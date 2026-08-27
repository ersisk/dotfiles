# claude-state — ~/.local/state/claude-menubar/sessions okuyucusu.
#
# Kontrat ana README'de yazili. Okuyucu burada duruyor cunku sozlesmeyi tanimlayan
# uygulama (ClaudeMenubar.swift) da bu dizinde; uc ayri cagiran source ediyor:
#   claude-next.sh                      (tmux, prefix + j)
#   .config/raycast/scripts/claude-jump.sh
#   .config/raycast/scripts/claude-sessions.sh
# Eskiden tmux tarafi kendi kopyasini tasiyordu, "tus basiminda dosya source etme"
# gerekcesiyle. Olculdu: fark yok (bos bash 2.2 ms, source'lu 2.0 ms).

STATE_DIR="${CLAUDE_MENUBAR_STATE_DIR:-$HOME/.local/state/claude-menubar/sessions}"

# Bastaki virgul sart: bir alan degerinin icindeki alinti isareti sahte anahtar
# eslesmesi uretmesin.
json_field() {
  local re=",\"$2\":\"([^\"]*)\""
  [[ "$1" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

json_num() {
  local re=",\"$2\":([0-9]+)"
  [[ "$1" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# Dikkat sirasi, menu cubugunun ikon sirasi degil: once bakman gerekeni yaz, boylece
# ilk satir her zaman dogru atlama hedefi olur. prio < 3 = cevap bekleyen.
state_prio() {
  case "$1" in
    waiting)    printf 0 ;;
    done-bg)    printf 1 ;;
    done)       printf 2 ;;
    bg-running) printf 3 ;;
    working)    printf 4 ;;
    *)          printf 5 ;;
  esac
}

state_icon() {
  case "$1" in
    waiting) printf '🔔' ;; done-bg) printf '☑️' ;; done) printf '✅' ;;
    bg-running) printf '⏳' ;; working) printf '🔄' ;; *) printf '⚪' ;;
  esac
}

state_label() {
  case "$1" in
    waiting) printf 'needs input' ;; done-bg) printf 'bg task done' ;;
    done) printf 'finished' ;; bg-running) printf 'bg task' ;;
    working) printf 'working' ;; *) printf 'idle' ;;
  esac
}

short_age() {
  local secs=$(( ${2:-$(date +%s)} - ${1:-0} ))
  (( secs < 0 )) && secs=0
  if   (( secs < 60 ));    then printf '%ds' "$secs"
  elif (( secs < 3600 ));  then printf '%dm' $(( secs / 60 ))
  elif (( secs < 86400 )); then printf '%dh' $(( secs / 3600 ))
  else printf '%dd' $(( secs / 86400 )); fi
}

# prio \t state \t project \t age \t session \t window \t pane \t socket \t detail
emit_rows() {
  local f line state sess now
  now=$(date +%s)   # satir basina degil, bir kez
  for f in "$STATE_DIR"/*.json; do
    [[ -r "$f" ]] || continue
    line=$(< "$f")
    state=$(json_field "$line" state)
    sess=$(json_field "$line" tmux_session)
    [[ -n "$sess" ]] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(state_prio "$state")" "$state" \
      "$(json_field "$line" project)" \
      "$(short_age "$(json_num "$line" updated_at)" "$now")" \
      "$sess" \
      "$(json_field "$line" tmux_window)" \
      "$(json_field "$line" tmux_pane)" \
      "$(json_field "$line" tmux_socket)" \
      "$(json_field "$line" detail)"
  done | sort -t"$(printf '\t')" -k1,1n -k5,5
}
