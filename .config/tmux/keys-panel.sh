#!/usr/bin/env bash
# keys-panel — kitty + tmux + aerospace + Raycast kisayollarini aranabilir bir
# listede gosterir.
#
# Kaynak config dosyalarinin kendisi (bkz keys-panel.py), ayri bir cheatsheet
# tutulmuyor. Enter secili satirin tuslarini panoya kopyalar.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/keys-panel.py"

if [[ ! -f "$PARSER" ]]; then
    echo "keys-panel.py bulunamadi: $PARSER" >&2
    exit 1
fi

rows="$(python3 "$PARSER")"
if [[ -z "$rows" ]]; then
    echo "kisayol bulunamadi" >&2
    exit 1
fi

# tmux icindeysek popup, degilsek dogrudan calis
if [[ -n "${TMUX:-}" && "${KEYS_PANEL_POPUP:-}" != "1" ]]; then
    exec tmux display-popup -w 88% -h 80% -E \
        "KEYS_PANEL_POPUP=1 '${BASH_SOURCE[0]}'"
fi

selection="$(printf '%s\n' "$rows" | fzf \
    --prompt='kisayol > ' \
    --header='Enter: tuslari kopyala · Esc: kapat' \
    --header-first \
    --layout=reverse \
    --info=inline \
    --border=rounded \
    --border-label=' Kisayollar (kitty · tmux · aerospace · raycast) ' \
    --ansi \
    --no-multi \
    --pointer='▶' \
    --color='label:bold' \
    --preview-window=hidden \
    || true)"

[[ -z "$selection" ]] && exit 0

# ilk iki kolon tuslar; aciklamayi atip panoya sadece onlari koy
# fzf --ansi secimi ham dondurur; renk kodlari panoya sizmasin
selection="$(printf '%s' "$selection" | sed $'s/\033\[[0-9;]*m//g')"
keys="$(printf '%s' "$selection" | awk -F'  +' '{
    out = $1
    if ($2 ~ /\^a/) out = out "  /  " $2
    print out
}')"

if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$keys" | pbcopy
    [[ -n "${TMUX:-}" ]] && tmux display-message -d 1500 "kopyalandi: $keys"
fi
