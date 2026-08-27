#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Sesh Session
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🗂
# @raycast.description kitty'yi kaldır ve eşleşen sesh oturumuna geç.
# @raycast.argument1 { "type": "text", "placeholder": "oturum", "optional": true }

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"
JUMP="${CLAUDE_JUMP:-$HOME/.local/bin/claude-jump}"
query="${1:-}"

# Argumansiz cagri en son kullanilan oturuma gider: sesh listesi zaten
# son-kullanim sirali, ilk sirada su an bagli olunan olabilecegi icin
# tmux'un kendi "son oturum" kaydi daha dogru cevap.
if [[ -z "$query" ]]; then
  target=$(tmux -S "$SOCKET" display-message -p '#{client_last_session}' 2>/dev/null)
else
  # Once tam eslesme, sonra fzf ile bulanik: "dot" -> "🧩 Dotfiles"
  target=$(sesh list 2>/dev/null | rg -Fx "$query" | head -1)
  [[ -n "$target" ]] || target=$(sesh list 2>/dev/null | fzf --filter="$query" 2>/dev/null | head -1)
fi
[[ -n "$target" ]] || { echo "eşleşen oturum yok: ${query:-<son>}"; exit 0; }

# Oturum henuz yoksa sesh olusturur; ekli bir tty olmadigi icin detached kurulur,
# switch-client sonra ona gecer.
if ! tmux -S "$SOCKET" has-session -t "$target" 2>/dev/null; then
  sesh connect --switch "$target" >/dev/null 2>&1 \
    || tmux -S "$SOCKET" new-session -d -s "$target" 2>/dev/null
fi

# Pencere/pane bilgisi verilmez: sadece oturuma gecilir, gerisi tmux'un
# hatirladigi son konum. Yukseltme claude-jump'ta, aerospace yarisi orada cozulu.
"$JUMP" "$SOCKET" "$target" "" ""
echo "→ $target"
