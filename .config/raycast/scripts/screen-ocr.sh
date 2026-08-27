#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Screen OCR
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🔤
# @raycast.description Bir ekran bölgesi seç, içindeki metni panoya kopyala.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

OCR="${SCREEN_OCR:-$HOME/.local/bin/screen-ocr}"
[[ -x "$OCR" ]] || { echo "screen-ocr yok — ~/.local/share/screen-ocr/build.sh" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# -i kullanici seciminden gecer, ekran kaydi izni istemez; tam ekran isterdi.
screencapture -i -x "$tmp/shot.png"
[[ -s "$tmp/shot.png" ]] || { echo "iptal edildi"; exit 0; }

text=$("$OCR" "$tmp/shot.png")
[[ -n "$text" ]] || { echo "metin bulunamadı"; exit 0; }

printf '%s' "$text" | pbcopy
lines=$(printf '%s\n' "$text" | wc -l | tr -d ' ')
printf '%s satır kopyalandı: %.60s…\n' "$lines" "$(printf '%s' "$text" | head -1)"
