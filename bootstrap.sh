#!/usr/bin/env bash
# Sets up this machine from the repo, or with `doctor` only reports what is missing.
# Every step is check-then-fix, so re-running it is safe and does only what is missing.
# The why behind each step lives in README.md; the steps no script can do are listed there too.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode="${1:-install}"
uid="$(id -u)"
failed=0

[[ "$(uname)" == Darwin ]] || { echo "bootstrap.sh is macOS-only; on Linux run: stow . -t ~" >&2; exit 1; }
[[ "$mode" == install || "$mode" == doctor ]] || { echo "usage: $0 [doctor]" >&2; exit 2; }

if [[ -t 1 ]]; then g=$'\e[32m' y=$'\e[33m' r=$'\e[31m' d=$'\e[2m' n=$'\e[0m'; else g='' y='' r='' d='' n=''; fi

# step <name> <check-fn> <fix-fn|manual:hint>
step() {
  local name="$1" check="$2" fix="$3"
  if "$check" &>/dev/null; then
    printf '%s ok %s %s\n' "$g" "$n" "$name"
    return
  fi
  if [[ "$fix" == manual:* ]]; then
    printf '%stodo%s %s %s— %s%s\n' "$y" "$n" "$name" "$d" "${fix#manual:}" "$n"
    failed=1
    return
  fi
  if [[ "$mode" == doctor ]]; then
    printf '%sFAIL%s %s\n' "$r" "$n" "$name"
    failed=1
    return
  fi
  printf '%sfix %s %s\n' "$y" "$n" "$name"
  if "$fix" && "$check" &>/dev/null; then
    printf '%s ok %s %s\n' "$g" "$n" "$name"
  else
    printf '%sFAIL%s %s\n' "$r" "$n" "$name"
    failed=1
  fi
}

# Brew's own bin first: fnm's node otherwise shadows it, and `brew bundle` then looks for the
# Brewfile's npm globals in fnm's prefix, reporting them missing although brew's node has them.
brew_env() { PATH="/opt/homebrew/bin:$PATH" "$@"; }

check_brew() { command -v brew; }
check_bundle() { brew_env brew bundle check --no-upgrade --file "$repo/Brewfile"; }
fix_bundle() { brew_env brew bundle install --no-upgrade --file "$repo/Brewfile"; }

stow_dry() { stow -n -v -d "$repo" -t "$HOME" . 2>&1; }
check_stow() { command -v stow && ! stow_dry | rg -q 'LINK:|UNLINK:|conflict|cannot stow|aborted'; }
fix_stow() {
  stow_dry | rg -q 'conflict|cannot stow|aborted' && { stow_dry | rg 'conflict|cannot stow|existing target' >&2; return 1; }
  stow -d "$repo" -t "$HOME" .
}

check_hooks() { [[ "$(git -C "$repo" config core.hooksPath)" == .config/git/hooks ]]; }
fix_hooks() { git -C "$repo" config core.hooksPath .config/git/hooks; }

work_paths="$HOME/.config/fish/conf.d/work-paths.fish"
check_work_paths() { [[ -f "$work_paths" ]]; }
fix_work_paths() {
  cp "$repo/.config/fish/conf.d/work-paths.fish.example" "$work_paths" &&
    echo "     ${d}placeholder paths copied — edit $work_paths${n}"
}

claude_settings="$HOME/.claude/settings.json"
check_claude_settings() { [[ -f "$claude_settings" ]]; }
fix_claude_settings() { mkdir -p "$HOME/.claude" && cp "$repo/.claude/settings.json.example" "$claude_settings"; }

app_support="$HOME/Library/Application Support"
check_link() { [[ "$(readlink "$2")" == "$1" ]]; }
fix_link() { mkdir -p "$(dirname "$2")" && ln -sf "$1" "$2"; }
check_lazygit() { check_link "$repo/.config/lazygit/config.yml" "$app_support/lazygit/config.yml"; }
fix_lazygit() { fix_link "$repo/.config/lazygit/config.yml" "$app_support/lazygit/config.yml"; }
check_lazydocker() { check_link "$repo/.config/lazydocker/config.yml" "$app_support/lazydocker/config.yml"; }
fix_lazydocker() { fix_link "$repo/.config/lazydocker/config.yml" "$app_support/lazydocker/config.yml"; }

# A binary older than its source is stale. Rebuilding zen-pip-defocus drops its Accessibility
# grant, so it is never rebuilt unless the source actually changed.
check_built() {
  local bin="$HOME/.local/bin/$1" src
  [[ -x "$bin" ]] || return 1
  for src in "$repo/.local/share/$1"/*.swift; do [[ "$src" -nt "$bin" ]] && return 1; done
  return 0
}
check_screen_ocr() { check_built screen-ocr; }
fix_screen_ocr() { "$repo/.local/share/screen-ocr/build.sh"; }
check_agent_menubar_bin() { check_built agent-menubar; }
fix_agent_menubar_bin() { "$repo/.local/share/agent-menubar/build.sh"; }
check_zen_pip_bin() { check_built zen-pip-defocus; }
fix_zen_pip_bin() {
  "$repo/.local/share/zen-pip-defocus/build.sh" &&
    echo "     ${d}rebuilt: remove and re-add zen-pip-defocus in Accessibility (toggling keeps the stale grant)${n}"
}

check_agent() {
  local label="$1" plist="$HOME/Library/LaunchAgents/$1.plist"
  check_link "$repo/.local/share/$2/$label.plist" "$plist" &&
    launchctl print "gui/$uid/$label" | rg -q 'state = running'
}
fix_agent() {
  local label="$1" plist="$HOME/Library/LaunchAgents/$1.plist"
  fix_link "$repo/.local/share/$2/$label.plist" "$plist" || return 1
  if launchctl print "gui/$uid/$label" &>/dev/null; then
    launchctl kickstart -k "gui/$uid/$label"
  else
    launchctl bootstrap "gui/$uid" "$plist"
  fi
}
check_agent_menubar() { check_agent com.ersanisik.agent-menubar agent-menubar; }
fix_agent_menubar() { fix_agent com.ersanisik.agent-menubar agent-menubar; }
check_zen_pip() { check_agent com.ersanisik.zen-pip-defocus zen-pip-defocus; }
fix_zen_pip() { fix_agent com.ersanisik.zen-pip-defocus zen-pip-defocus; }
check_ollama() { check_agent com.ersanisik.ollama ollama; }
fix_ollama() { fix_agent com.ersanisik.ollama ollama; }

ollama_cli() { OLLAMA_HOST=127.0.0.1:11435 ollama "$@"; }
check_qwen3() { ollama_cli list | awk 'NR > 1 { print $1 }' | rg -q '^qwen3:'; }
fix_qwen3() {
  local i
  for i in {1..10}; do ollama_cli list &>/dev/null && break; sleep 1; done
  ollama_cli pull qwen3
}

check_borders() { brew services info borders --json | jq -e '.[0].running'; }
fix_borders() { brew services start borders; }

scoot_domain=com.mjrusso.Scoot
scoot_keys=(
  'KeyboardShortcuts_useElementBasedNavigation {"carbonKeyCode":38,"carbonModifiers":4608}'
  'KeyboardShortcuts_useGridBasedNavigation {"carbonKeyCode":40,"carbonModifiers":4608}'
  'KeyboardShortcuts_useFreestyleNavigation {"carbonKeyCode":37,"carbonModifiers":4608}'
)
check_scoot_keys() {
  local kv
  for kv in "${scoot_keys[@]}"; do
    [[ "$(defaults read "$scoot_domain" "${kv%% *}" 2>/dev/null)" == "${kv#* }" ]] || return 1
  done
}
fix_scoot_keys() {
  local kv
  osascript -e 'quit app "Scoot"'
  for kv in "${scoot_keys[@]}"; do defaults write "$scoot_domain" "${kv%% *}" -string "${kv#* }"; done
  open -a Scoot
}
check_scoot_login() {
  osascript -e 'tell application "System Events" to get the name of every login item' | tr ',' '\n' | rg -qx ' ?Scoot'
}
fix_scoot_login() {
  osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Scoot.app", hidden:false}'
}

check_opencode_key() { [[ -s "$HOME/.config/opencode/llmroute.key" ]]; }
check_jira() { [[ -f "$HOME/.config/.jira/.config.yml" ]]; }

step "homebrew" check_brew "manual:install from https://brew.sh, then re-run"
check_brew &>/dev/null || exit 1
step "Brewfile" check_bundle fix_bundle
step "stow links" check_stow fix_stow
step "git hooksPath" check_hooks fix_hooks
step "fish work-paths.fish" check_work_paths fix_work_paths
step "claude settings.json" check_claude_settings fix_claude_settings
step "lazygit config link" check_lazygit fix_lazygit
step "lazydocker config link" check_lazydocker fix_lazydocker
step "screen-ocr binary" check_screen_ocr fix_screen_ocr
step "agent-menubar binary" check_agent_menubar_bin fix_agent_menubar_bin
step "agent-menubar agent" check_agent_menubar fix_agent_menubar
step "zen-pip-defocus binary" check_zen_pip_bin fix_zen_pip_bin
step "zen-pip-defocus agent" check_zen_pip fix_zen_pip
step "ollama agent (:11435)" check_ollama fix_ollama
step "ollama qwen3 model" check_qwen3 fix_qwen3
step "borders service" check_borders fix_borders
step "Scoot hotkeys (⌃⇧J/K/L)" check_scoot_keys fix_scoot_keys
step "Scoot login item" check_scoot_login fix_scoot_login
step "opencode gateway key" check_opencode_key "manual:write ~/.config/opencode/llmroute.key (README)"
step "jira-cli config" check_jira "manual:jira init --installation cloud --auth-type basic (optional)"

if [[ "$mode" == install ]]; then
  cat <<EOF

${d}Not scriptable, see README "Manual steps": Raycast script dir and AI commands,
Accessibility for Scoot / zen-pip-defocus, the Graylog userscript in Violentmonkey.${n}
EOF
fi
exit "$failed"
