# Reader for the claude-menubar state files, sourced by the Raycast script
# commands. Same single-line JSON contract claude-next.sh parses; that one keeps
# its own copy on purpose — it runs on a tmux keypress and must not pay for
# sourcing a file it does not otherwise need.

STATE_DIR="${CLAUDE_MENUBAR_STATE_DIR:-$HOME/.local/state/claude-menubar/sessions}"
JUMP="${CLAUDE_JUMP:-$HOME/.local/bin/claude-jump}"

# Leading comma is required: it stops a quote inside a value from matching as a key.
json_field() {
  local re=",\"$2\":\"([^\"]*)\""
  [[ "$1" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

json_num() {
  local re=",\"$2\":([0-9]+)"
  [[ "$1" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# Attention order, not the menu bar's icon order: what you would want to look at
# first, so row 1 is always the right jump target.
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
  local secs=$(( $(date +%s) - ${1:-0} ))
  (( secs < 0 )) && secs=0
  if   (( secs < 60 ));   then printf '%ds' "$secs"
  elif (( secs < 3600 )); then printf '%dm' $(( secs / 60 ))
  elif (( secs < 86400 )); then printf '%dh' $(( secs / 3600 ))
  else printf '%dd' $(( secs / 86400 )); fi
}

# prio \t state \t project \t age \t session \t window \t pane \t socket \t detail
emit_rows() {
  local f line state sess
  for f in "$STATE_DIR"/*.json; do
    [[ -r "$f" ]] || continue
    line=$(< "$f")
    state=$(json_field "$line" state)
    sess=$(json_field "$line" tmux_session)
    [[ -n "$sess" ]] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(state_prio "$state")" "$state" \
      "$(json_field "$line" project)" \
      "$(short_age "$(json_num "$line" updated_at)")" \
      "$sess" \
      "$(json_field "$line" tmux_window)" \
      "$(json_field "$line" tmux_pane)" \
      "$(json_field "$line" tmux_socket)" \
      "$(json_field "$line" detail)"
  done | sort -t"$(printf '\t')" -k1,1n -k5,5
}
