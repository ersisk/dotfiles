#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Kisayol Paneli
# @raycast.mode silent
# @raycast.packageName Tools
# @raycast.icon ⌨️
# @raycast.description kitty'yi kaldır ve kısayol panelini tmux popup'ında aç.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

SOCKET="${TMUX_SOCKET:-/tmp/tmux-$(id -u)/default}"
JUMP="${CLAUDE_JUMP:-$HOME/.local/bin/claude-jump}"
PANEL="$HOME/.config/tmux/keys-panel.sh"

# Panel tmux popup'i, yani bir client sart. Yeni bir kitty penceresi acmak da
# mumkundu; aerospace onu bulundugun workspace'e dosiyor, panel de gorsel olarak
# yerinden oynatiyordu.
client=$(tmux -S "$SOCKET" list-clients -F '#{client_name}' 2>/dev/null | head -1)
[[ -n "$client" ]] || { echo "tmux client yok"; exit 0; }

# Bos session: claude-jump sadece kitty'yi kaldirip cikar. Yukseltme orada
# cozulu (aerospace yarisi dahil), ikinci kez cozulmesin.
"$JUMP" "$SOCKET" "" "" ""

# -E olmadan popup kapanana kadar bloklar ve Raycast spinner'da bekler; & ile
# birakiliyor. KEYS_PANEL_POPUP panelin kendi popup sarmalayicisini atlatir.
tmux -S "$SOCKET" display-popup -c "$client" -E -w 88% -h 80% \
    "KEYS_PANEL_POPUP=1 '$PANEL'" &
