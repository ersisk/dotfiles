#!/usr/bin/env bash
# claude-last-msg — bir Claude oturumunun son kullanici-gorunur mesajini tek satira indirir.
#
# claude-tmux-notify (Stop/Notification hook'unda) cagirir; sonuc pencerenin
# @claude_last option'ina yazilir, claude-next.sh onizlemede gosterir.
# Transcript yoksa veya okunabilir mesaj yoksa hicbir sey yazmaz.

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
        # <observation> gibi ic bloklar ve kod cite fence'leri kullaniciya yazilan metin degil
        if not t or t.startswith("<") or t.startswith("```"):
            continue
        last = t

if not last:
    sys.exit(0)

# Ilk anlamli satir: baslik isaretleri, liste imleri ve markdown vurgusu atilir
for raw in last.split("\n"):
    line = re.sub(r"^[#>\-*\d.\s]+", "", raw).strip()
    line = re.sub(r"[*_`]", "", line)
    if len(line) >= 3:
        print(line[:59] + "…" if len(line) > 60 else line)
        break
PY
