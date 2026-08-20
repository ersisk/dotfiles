"""Kitty ve tmux kisayollarini fzf satirlarina cevirir (bkz keys-panel.sh).

Kaynak dogrudan config dosyalari: kitty.conf'ta her map'in ustundeki yorum
satiri, tmux tarafinda ise bind'lerin -N notu. Boylece yeni bir kisayol
eklendiginde burada guncelleme gerekmez.

tmux -N notlari "⌘+g lazygit" formatinda oldugu icin kitty esiyle ayni satirda
birlestirilebiliyor; eslesmeyenler kendi satirinda kalir.
"""

import os
import re
import shlex
import sys

HOME = os.path.expanduser("~")
KITTY_CONF = os.path.join(HOME, ".config/kitty/kitty.conf")
TMUX_CONFS = [
    os.path.join(HOME, ".config/tmux/utility.conf"),
    os.path.join(HOME, ".config/tmux/tmux.conf"),
]

# "(Cmd+Shift+E -> Ctrl+A, Shift+E)" gibi kuyruklar yorumun anlamli kismini bogar
ARROW = re.compile(r"\s*\(?\s*(Cmd|⌘)[^)]*->[^)]*\)?\s*$", re.IGNORECASE)
MAP = re.compile(r"^map\s+(\S+)\s+(.*)$")
# send_text all \x01G -> prefix'ten sonra basilan tus ("G"); eslestirmenin asil anahtari
SENDS = re.compile(r"^send_text\s+all\s+\\x01(\\x(?P<hex>[0-9a-fA-F]{2})|(?P<lit>.))")
SECTION = re.compile(r"^--\s*(.*?)\s*--$")
# -N notu, ardindan opsiyonel flag'ler, sonra tus + komut
NOTE = re.compile(r"""^bind(?:-key)?\s+(?:-N\s+(?P<q>["'])(?P<note>.*?)(?P=q)\s*)?(?P<rest>.*)$""")
FLAGS = re.compile(r"^(?:-[a-zA-Z]+\s+|-T\s+\S+\s+)*")
# notun basindaki "⌘+⇧+K" gibi kitty esi
EQUIV = re.compile(r"^((?:⌘|⇧|⌃|⌥|\+)+[^\s]*)\s+(.*)$")

PREFIX = "^a"
GLYPHS = {"cmd": "⌘", "shift": "⇧", "ctrl": "⌃", "alt": "⌥", "opt": "⌥"}
SKIP_DESC = ("note:", "not:")


def clean(text):
    return ARROW.sub("", text.strip()).strip(" -–—")


def pretty_kitty(key):
    out = []
    for part in key.split("+"):
        low = part.lower()
        if low in GLYPHS:
            out.append(GLYPHS[low])
        elif len(part) == 1:
            out.append(part.upper())
        else:
            out.append(part.title())
    return "+".join(out)


def norm(text):
    """Eslestirme icin: kucuk harf, noktalama yok."""
    return re.sub(r"[^\w]+", "", text.lower())


def parse_kitty():
    rows = []
    try:
        with open(KITTY_CONF, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return rows

    section = ""
    pending = []
    seen_sends = set()
    for line in lines:
        stripped = line.strip()

        if stripped.startswith("#"):
            body = stripped.lstrip("#").strip()
            sec = SECTION.match(body)
            if sec:
                section = clean(sec.group(1)).rstrip("(").strip()
                pending = []
            elif body and not body.startswith("="):
                # "Note: ..." aciklama degil, uyari
                if not body.lower().startswith(SKIP_DESC):
                    pending.append(body)
            continue

        if not stripped:
            pending = []
            continue

        m = MAP.match(stripped)
        if not m:
            pending = []
            continue

        key, action = m.group(1), m.group(2).strip()
        desc = clean(pending[-1]) if pending else ""
        sends = ""
        sm = SENDS.match(action)
        if sm:
            sends = chr(int(sm.group("hex"), 16)) if sm.group("hex") else sm.group("lit")
            # ayni tusu gonderen ikinci map, klavye layout varyanti; atla
            if sends in seen_sends:
                pending = []
                continue
            seen_sends.add(sends)
        if not desc:
            desc = f"tmux: {PREFIX} {sends}" if sends else action.replace("_", " ")
        rows.append({
            "key": pretty_kitty(key),
            "desc": desc,
            "section": section,
            "sends": sends,
            "src": "kitty",
        })
        pending = []
    return rows


def parse_tmux():
    rows = []
    for path in TMUX_CONFS:
        try:
            with open(path, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except OSError:
            continue

        for line in lines:
            stripped = line.strip()
            if not stripped.startswith(("bind ", "bind-key ")):
                continue
            if "-T copy-mode" in stripped:
                continue

            m = NOTE.match(stripped)
            if not m:
                continue
            rest = FLAGS.sub("", m.group("rest")).strip()
            if not rest:
                continue

            # '"' ve '%' gibi tuslar quote'lu; shlex dogru ayirir
            try:
                tokens = shlex.split(rest, comments=True)
            except ValueError:
                tokens = rest.split()
            if not tokens:
                continue

            key = tokens[0]
            cmd = " ".join(tokens[1:])
            note = (m.group("note") or "").strip()

            desc, equiv = note, ""
            em = EQUIV.match(note)
            if em:
                equiv, desc = em.group(1), em.group(2)
            if not desc:
                desc = cmd[:60]

            rows.append({
                "raw": key,
                "key": f"{PREFIX} {key}",
                "desc": desc,
                "equiv": equiv,
                "src": "tmux",
            })
    return rows


def merge(kitty_rows, tmux_rows):
    """Ayni isi yapan kitty+tmux ciftlerini tek satirda birlestirir.

    Anahtar, kitty'nin tmux'a gonderdigi tus (\x01G -> "G"); -N notundaki
    ⌘ esi sadece dogrulama/yedek olarak kullanilir.
    """
    by_send = {}
    for row in kitty_rows:
        if row.get("sends"):
            by_send.setdefault(row["sends"], []).append(row)

    merged = []
    used = set()
    for t in tmux_rows:
        match = None
        for k in by_send.get(t["raw"], []):
            if id(k) not in used:
                match = k
                break
        if match is None:
            for k in kitty_rows:
                if id(k) not in used and norm(k["desc"]) == norm(t["desc"]):
                    match = k
                    break

        if match is not None:
            used.add(id(match))
            desc = match["desc"] if len(match["desc"]) >= len(t["desc"]) else t["desc"]
            merged.append({
                "kitty": match["key"],
                "tmux": t["key"],
                "desc": desc,
                "section": match.get("section", ""),
            })
        else:
            merged.append({"kitty": "", "tmux": t["key"], "desc": t["desc"], "section": "tmux"})

    for k in kitty_rows:
        if id(k) not in used:
            merged.append({"kitty": k["key"], "tmux": "", "desc": k["desc"], "section": k.get("section", "")})
    return merged


# ok/isimli tuslar harf ve rakamlardan sonra gelsin
NAMED_KEY_ORDER = ("Left", "Right", "Up", "Down", "Equal", "Minus")


def sort_key(row):
    """Tus sirasina gore: once ana tus, sonra modifier sayisi.

    Boylece ⌘+A ile ⌘+⇧+A yan yana gelir ve sade olan (az modifier) once gelir.
    Kitty esi olmayan, yalniz tmux satirlari en sona duser.
    """
    key = row["kitty"]
    if not key:
        return (3, 0, "", 0, row["desc"].lower())

    parts = key.split("+")
    base = parts[-1]
    mods = len(parts) - 1

    if len(base) == 1 and base.isdigit():
        return (0, 0, base, mods, "")
    if len(base) == 1:
        return (1, 0, base.lower(), mods, "")
    idx = NAMED_KEY_ORDER.index(base) if base in NAMED_KEY_ORDER else len(NAMED_KEY_ORDER)
    return (2, idx, base.lower(), mods, "")


def main():
    rows = merge(parse_kitty(), parse_tmux())
    if not rows:
        sys.exit("kisayol bulunamadi")

    kw = max((len(r["kitty"]) for r in rows), default=0)
    tw = max((len(r["tmux"]) for r in rows), default=0)
    for r in sorted(rows, key=sort_key):
        sec = f"  · {r['section']}" if r["section"] else ""
        print(f"{r['kitty']:<{kw}}  {r['tmux']:<{tw}}  {r['desc']}{sec}")


if __name__ == "__main__":
    main()
