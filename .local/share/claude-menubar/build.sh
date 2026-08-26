#!/usr/bin/env bash
# Builds ClaudeMenubar.swift into ~/.local/bin/claude-menubar and restarts the
# LaunchAgent when one is loaded. The binary is not versioned (see .gitignore).
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${HOME}/.local/bin/claude-menubar"
label="com.ersanisik.claude-menubar"

mkdir -p "$(dirname "$out")"
swiftc -O -framework AppKit -o "$out" "${src_dir}/ClaudeMenubar.swift"
echo "built $out"

if launchctl print "gui/$(id -u)/${label}" &>/dev/null; then
  launchctl kickstart -k "gui/$(id -u)/${label}"
  echo "restarted ${label}"
fi
