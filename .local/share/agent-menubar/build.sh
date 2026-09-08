#!/usr/bin/env bash
# Builds AgentMenubar.swift into ~/.local/bin/agent-menubar and restarts the
# LaunchAgent when one is loaded. The binary is not versioned (see .gitignore).
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${HOME}/.local/bin/agent-menubar"
label="com.ersanisik.agent-menubar"

mkdir -p "$(dirname "$out")"
swiftc -O -framework AppKit -framework Carbon -o "$out" "${src_dir}/AgentMenubar.swift"
echo "built $out"

if launchctl print "gui/$(id -u)/${label}" &>/dev/null; then
  launchctl kickstart -k "gui/$(id -u)/${label}"
  echo "restarted ${label}"
fi
