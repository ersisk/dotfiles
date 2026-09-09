#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Zen Window
# @raycast.mode compact
# @raycast.packageName Tools
# @raycast.icon 🌐
# @raycast.description Open a new Zen window on the chosen aerospace workspace and Zen space.
# @raycast.argument1 { "type": "dropdown", "placeholder": "workspace", "data": [{"title": "Current", "value": "focused"}, {"title": "A · Browsers", "value": "A"}, {"title": "B · Zen", "value": "B"}, {"title": "C · Terminal", "value": "C"}, {"title": "D · Database", "value": "D"}, {"title": "G · Passwords", "value": "G"}, {"title": "I · IDE", "value": "I"}, {"title": "M · Messaging", "value": "M"}, {"title": "N · Notes", "value": "N"}, {"title": "P · API", "value": "P"}, {"title": "W · Mail", "value": "W"}, {"title": "X · Scratch", "value": "X"}, {"title": "Z · Slack", "value": "Z"}] }
# @raycast.argument2 { "type": "dropdown", "placeholder": "space", "optional": true, "data": [{"title": "Current", "value": "current"}, {"title": "1 · Genel", "value": "1"}, {"title": "2 · Personel", "value": "2"}, {"title": "Private", "value": "private"}] }

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
set -uo pipefail

BUNDLE_ID="app.zen-browser.zen"
ZEN_BIN="${ZEN_BIN:-/Applications/Zen.app/Contents/MacOS/zen}"
target="${1:-focused}"
space="${2:-current}"

[[ -x "$ZEN_BIN" ]] || { echo "zen binary not found: $ZEN_BIN"; exit 1; }

zen_ids() {
  aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' 2>/dev/null \
    | awk -v b="$BUNDLE_ID" '$2 == b { print $1 }'
}

# Raycast floats on top of the workspace you were on, so the focused one is still it.
if [[ "$target" == "focused" ]]; then
  target=$(aerospace list-workspaces --focused 2>/dev/null)
fi
[[ -n "$target" ]] || { echo "no target workspace"; exit 1; }

before=$(zen_ids)

# Running the binary while Zen is up forwards the flag to the live instance; `open -n`
# would start a second one and hit the profile lock instead.
if [[ "$space" == "private" ]]; then
  "$ZEN_BIN" --private-window >/dev/null 2>&1 &
else
  "$ZEN_BIN" --new-window about:newtab >/dev/null 2>&1 &
fi

# The window can only be moved once aerospace knows about it, and a cold start takes
# seconds while a forward takes tens of ms — hence polling for the new id.
wid=""
for _ in $(seq 100); do
  wid=$(zen_ids | grep -vxF -f <(printf '%s\n' "$before") | head -1)
  [[ -n "$wid" ]] && break
  sleep 0.1
done
[[ -n "$wid" ]] || { echo "no new Zen window appeared"; exit 1; }

# on-window-detected pins every Zen window to B and may still be in flight when the
# window first shows up in the list, which would undo the move; verify and retry.
for _ in 1 2 3; do
  aerospace move-node-to-workspace --window-id "$wid" "$target" 2>/dev/null
  sleep 0.1
  landed=$(aerospace list-windows --all --format '%{window-id} %{workspace}' 2>/dev/null \
    | awk -v w="$wid" '$1 == w { print $2 }')
  [[ "$landed" == "$target" ]] && break
done

# Also switches the workspace: a plain move leaves you where you were, and the
# keystroke below needs the new window frontmost.
aerospace focus --window-id "$wid" 2>/dev/null

# Zen exposes no way to pick a space from the outside — no CLI flag, and the Spaces
# menu only cycles. What it does have is cmd_zenWorkspaceSwitch1..10, bound to ⌘⌥1..0
# in zen-keyboard-shortcuts.json; each new window reads that file at startup, so the
# window we just opened has them. Sent by position, not by name: the number is the
# space's place in the sidebar. Nothing happens if the binding is gone.
case "$space" in
  current) echo "→ Zen on $target" ;;
  # A private window has no spaces at all, so the argument doubles as the private
  # switch instead of adding a third dropdown that could contradict this one.
  private) echo "→ Zen private on $target" ;;
  *)
    # macOS virtual key codes for 1..9 and 0. `key code` presses the physical key, so a
    # layout where ⌥1 types another character still matches the binding.
    keycode=$(echo "18 19 20 21 23 22 26 28 25 29" | cut -d' ' -f"$space")
    osascript -e "tell application \"System Events\" to key code $keycode using {command down, option down}" >/dev/null 2>&1 \
      || echo "space switch needs Accessibility permission"
    echo "→ Zen on $target, space $space"
    ;;
esac
