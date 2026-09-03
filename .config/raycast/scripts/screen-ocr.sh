#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Screen OCR
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🔤
# @raycast.description Select a screen region and copy the text in it to the clipboard.

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

OCR="${SCREEN_OCR:-$HOME/.local/bin/screen-ocr}"
[[ -x "$OCR" ]] || { echo "screen-ocr not found — ~/.local/share/screen-ocr/build.sh" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# -i goes through a user selection and needs no screen-recording permission; full screen would.
screencapture -i -x "$tmp/shot.png"
[[ -s "$tmp/shot.png" ]] || { echo "cancelled"; exit 0; }

text=$("$OCR" "$tmp/shot.png")
[[ -n "$text" ]] || { echo "no text found"; exit 0; }

printf '%s' "$text" | pbcopy
lines=$(printf '%s\n' "$text" | wc -l | tr -d ' ')
printf '%s lines copied: %.60s…\n' "$lines" "$(printf '%s' "$text" | head -1)"
