"""Kitty, tmux, aerospace ve Raycast kisayollarini fzf satirlarina cevirir
(bkz keys-panel.sh).

Kaynak dogrudan config dosyalari: kitty.conf'ta her map'in ustundeki yorum
satiri, tmux tarafinda ise bind'lerin -N notu, aerospace'te [mode.*.binding]
tablolarindaki satir sonu yorumu. Boylece yeni bir kisayol eklendiginde burada
guncelleme gerekmez.

Tek istisna Raycast: script hotkey'leri Raycast'in kendi sifreli state'inde
duruyor, dosyada tutulan tek kayit scripts/README.md'deki tablo — panel de onu
okuyor. Tablo yanlissa panel de yanlis soyler.

tmux -N notlari "⌘+g lazygit" formatinda oldugu icin kitty esiyle ayni satirda
birlestirilebiliyor; eslesmeyenler kendi satirinda kalir.

Kisayollardan sonra fish alias'lari ve fish/functions altindaki komutlar
"alias" bolumunde listelenir.
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
FISH_CONF = os.path.join(HOME, ".config/fish/config.fish")
FISH_FUNCTIONS = os.path.join(HOME, ".config/fish/functions")
AEROSPACE_CONF = os.path.join(HOME, ".aerospace.toml")
RAYCAST_README = os.path.join(HOME, ".config/raycast/scripts/README.md")

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

# alias adi ve komutu; deger tirnakli ya da tirnaksiz, "=" opsiyonel
ALIAS = re.compile(r"""^alias\s+(?P<name>[\w.-]+)\s*=?\s*(?P<q>["']?)(?P<cmd>.*?)(?P=q)$""")

# aerospace: sadece [mode.*.binding] altindaki satirlar kisayol. [gaps] ya da
# [[on-window-detected]] altindaki "key = value" satirlari da ayni sekle uyuyor,
# tablo basligini takip etmek onlari ayirmanin tek yolu.
AEROSPACE_MODE = re.compile(r"^\[mode\.(?P<mode>[\w-]+)\.binding\]")
AEROSPACE_BIND = re.compile(r"^(?P<key>[a-z0-9]+(?:-[a-z0-9]+)*)\s*=\s*(?P<val>.+)$", re.IGNORECASE)
QUOTED = re.compile(r"'([^']*)'|\"([^\"]*)\"")
WORKSPACE = re.compile(r"^workspace (\S+)$")
MOVE_NODE = re.compile(r"^move-node-to-workspace (\S+)$")
# markdown tablo satiri: | Jump to Claude | `⌃⌥J` | ... |
MD_ROW = re.compile(r"^\|(?P<cells>.+)\|$")
# "⌃⌥J" -> modifier dizisi + ana tus
GLYPH_RUN = re.compile(r"^(?P<mods>[⌘⇧⌃⌥]+)(?P<base>.+)$")

PREFIX = "^a"
# fzf --ansi ile okunur; alias satirlarini kisayollardan gorsel olarak ayirir
CYAN, DIM, RESET = "\033[36m", "\033[2m", "\033[0m"
GLYPHS = {"cmd": "⌘", "shift": "⇧", "ctrl": "⌃", "alt": "⌥", "opt": "⌥"}
SKIP_DESC = ("note:", "not:")


def clean(text):
    return ARROW.sub("", text.strip()).strip(" -–—")


def pretty_key(key, sep="+"):
    """'cmd+shift+k' -> '⌘+⇧+K'; aerospace tuslari '-' ile ayrildigi icin sep var."""
    out = []
    for part in key.split(sep):
        low = part.lower()
        if low in GLYPHS:
            out.append(GLYPHS[low])
        elif len(part) == 1:
            out.append(part.upper())
        else:
            out.append(part.title())
    return "+".join(out)


def pretty_glyphs(key):
    """'⌃⌥J' -> '⌃+⌥+J'; panelin geri kalani '+' ile ayrilmis tuslar bekliyor."""
    m = GLYPH_RUN.match(key)
    if not m:
        return key
    base = m.group("base")
    return "+".join(list(m.group("mods")) + [base.upper() if len(base) == 1 else base.title()])


def split_comment(text):
    """TOML satirini deger ve satir sonu yorumuna ayirir; tirnak icindeki # yorum degil."""
    quote = ""
    for i, ch in enumerate(text):
        if quote:
            if ch == quote:
                quote = ""
        elif ch in "'\"":
            quote = ch
        elif ch == "#":
            return text[:i].strip(), text[i + 1:].strip()
    return text.strip(), ""


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
            "key": pretty_key(key),
            "desc": desc,
            "section": section,
            "sends": sends,
            "src": "kitty",
        })
        pending = []
    return rows


def parse_aerospace():
    """[mode.*.binding] tablolarindaki bindingler; ana mod disindakiler prefix'li yazilir."""
    try:
        with open(AEROSPACE_CONF, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return []

    mode = ""
    service_prefix = ""
    pending = ""
    parsed = []
    for line in lines:
        stripped = line.strip()
        if not pending:
            if stripped.startswith("["):
                m = AEROSPACE_MODE.match(stripped)
                mode = m.group("mode") if m else ""
                continue
            if not mode or not stripped or stripped.startswith("#"):
                continue
        # cok satirli dizi: kapanan koseli paranteze kadar birlestir
        pending = f"{pending} {stripped}" if pending else stripped
        if pending.count("[") > pending.count("]"):
            continue
        text, pending = pending, ""

        m = AEROSPACE_BIND.match(text)
        if not m:
            continue
        value, note = split_comment(m.group("val"))
        cmds = [a or b for a, b in QUOTED.findall(value)]
        if not cmds:
            continue
        key = pretty_key(m.group("key"), sep="-")
        # service moduna hangi tusun soktugu configden okunur, sabitlenmez.
        # Prefix '+' olmadan yazilir: tus kolonunu 6 karakter daraltiyor ve
        # Raycast README'sinin "⌃⌥J" yazimiyla ayni.
        if cmds == ["mode service"]:
            service_prefix = key.replace("+", "")
        parsed.append({
            # her service-mode binding'i 'mode main' ile bitiyor; tekrar eden gurultu
            "cmd": " · ".join(c for c in cmds if c != "mode main") or cmds[0],
            "key": f"{service_prefix} {key}" if mode != "main" and service_prefix else key,
            "note": note,
        })

    # move-node-to-workspace satirlarinda yorum yok; workspace binding'inin notunu tasi
    notes = {}
    for row in parsed:
        m = WORKSPACE.match(row["cmd"])
        if m and row["note"]:
            notes[m.group(1)] = row["note"]

    rows = []
    for row in parsed:
        note = row["note"]
        if not note:
            m = MOVE_NODE.match(row["cmd"])
            note = notes.get(m.group(1), "") if m else ""
        # aerospace yorumlarinin kendisi parantez tasiyor; ayirici olarak tire kullan
        desc = f"{row['cmd']} — {note}" if note else row["cmd"]
        rows.append({"kitty": row["key"], "tmux": "", "desc": desc, "section": "aerospace"})
    return rows


def parse_raycast():
    """scripts/README.md'deki hotkey tablosu - bkz modul docstring'i."""
    try:
        with open(RAYCAST_README, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return []

    rows = []
    for line in lines:
        m = MD_ROW.match(line.strip())
        if not m:
            continue
        cells = [c.strip() for c in m.group("cells").split("|")]
        if len(cells) != 3:
            continue
        name, key, what = cells
        # baslik ve --- ayirici satirlari tus kolonundan dusuyor
        if not GLYPH_RUN.match(key.strip("`")):
            continue
        rows.append({
            "kitty": pretty_glyphs(key.strip("`")),
            "tmux": "",
            "desc": f"{name} — {what}",
            "section": "raycast",
        })
    return rows


def parse_alias():
    """config.fish alias'lari + fish/functions/*.fish (ozel komutlar)."""
    rows = []
    try:
        with open(FISH_CONF, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        lines = []

    for line in lines:
        m = ALIAS.match(line.strip())
        if not m:
            continue
        rows.append({
            "kitty": m.group("name"),
            "tmux": "",
            "desc": m.group("cmd").strip(),
            "section": "alias",
        })

    try:
        names = sorted(
            f[:-5] for f in os.listdir(FISH_FUNCTIONS) if f.endswith(".fish")
        )
    except OSError:
        names = []
    for name in names:
        rows.append({"kitty": name, "tmux": "", "desc": "fish function", "section": "alias"})
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
    if row.get("section") == "alias":
        return (4, 0, "", 0, row["kitty"].lower())

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
    rows = merge(parse_kitty(), parse_tmux()) + parse_aerospace() + parse_raycast() + parse_alias()
    if not rows:
        sys.exit("kisayol bulunamadi")

    kw = max((len(r["kitty"]) for r in rows), default=0)
    tw = max((len(r["tmux"]) for r in rows), default=0)
    for r in sorted(rows, key=sort_key):
        sec = f"  · {r['section']}" if r["section"] else ""
        # hizalama ANSI kodlarindan etkilenmesin: once padle, sonra renklendir
        name = f"{r['kitty']:<{kw}}"
        rest = f"{r['tmux']:<{tw}}  {r['desc']}{sec}"
        if r["section"] == "alias":
            print(f"{CYAN}{name}{RESET}  {DIM}{rest}{RESET}")
        else:
            print(f"{name}  {rest}")


if __name__ == "__main__":
    main()
