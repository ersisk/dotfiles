#!/usr/bin/env bash
# claude-last-msg — reduces the last user-visible message of a Claude session to one line.
#
# Called by claude-tmux-notify (in the Stop/Notification hook); the result is
# written to the window's @claude_last option and shown by claude-next.sh in its
# preview. With no transcript or no readable message it prints nothing.

set -uo pipefail

transcript="${1:-}"
[[ -r "$transcript" ]] || exit 0
command -v python3 >/dev/null || exit 0

python3 - "$transcript" <<'PY'
import sys, json, re

path = sys.argv[1]
try:
    with open(path, errors="ignore") as f:
        lines = f.readlines()[-200:]
except OSError:
    sys.exit(0)

last = None
for l in lines:
    try:
        d = json.loads(l)
    except Exception:
        continue
    if d.get("type") != "assistant" or d.get("isSidechain"):
        continue
    for b in d.get("message", {}).get("content", []) or []:
        if b.get("type") != "text":
            continue
        t = (b.get("text") or "").strip()
        # internal blocks like <observation> and code fences are not text written to the user
        if not t or t.startswith("<") or t.startswith("```"):
            continue
        last = t

if not last:
    sys.exit(0)

# The first meaningful line: heading marks, list bullets and markdown emphasis are stripped
for raw in last.split("\n"):
    line = re.sub(r"^[#>\-*\d.\s]+", "", raw).strip()
    line = re.sub(r"[*_`]", "", line)
    if len(line) >= 3:
        print(line[:59] + "…" if len(line) > 60 else line)
        break
PY
