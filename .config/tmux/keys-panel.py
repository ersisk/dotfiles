"""Turns kitty, tmux, aerospace and Raycast shortcuts into fzf rows
(see keys-panel.sh).

The source is the config files themselves: the comment above each map in
kitty.conf, the -N note on each tmux bind, the end-of-line comment in the
aerospace [mode.*.binding] tables. So a new binding needs no update here.

The one exception is Raycast: script hotkeys live in Raycast's own encrypted
state, and the only file-based record is the table in scripts/README.md — which
is what the panel reads. A wrong table means a wrong panel.

tmux -N notes are written as "⌘+g lazygit", so they can be merged onto the same
row as their kitty twin; unmatched ones keep their own row.

After the shortcuts come the fish aliases and the commands under fish/functions,
listed in the "alias" section.
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

# tails like "(Cmd+Shift+E -> Ctrl+A, Shift+E)" drown out the meaningful part of the comment
ARROW = re.compile(r"\s*\(?\s*(Cmd|⌘)[^)]*->[^)]*\)?\s*$", re.IGNORECASE)
MAP = re.compile(r"^map\s+(\S+)\s+(.*)$")
# send_text all \x01G -> the key pressed after the prefix ("G"); the real matching key
SENDS = re.compile(r"^send_text\s+all\s+\\x01(\\x(?P<hex>[0-9a-fA-F]{2})|(?P<lit>.))")
SECTION = re.compile(r"^--\s*(.*?)\s*--$")
# the -N note, then optional flags, then key + command
NOTE = re.compile(r"""^bind(?:-key)?\s+(?:-N\s+(?P<q>["'])(?P<note>.*?)(?P=q)\s*)?(?P<rest>.*)$""")
FLAGS = re.compile(r"^(?:-[a-zA-Z]+\s+|-T\s+\S+\s+)*")
# the kitty twin at the head of the note, e.g. "⌘+⇧+K"
EQUIV = re.compile(r"^((?:⌘|⇧|⌃|⌥|\+)+[^\s]*)\s+(.*)$")

# alias name and command; the value may be quoted or not, "=" optional
ALIAS = re.compile(r"""^alias\s+(?P<name>[\w.-]+)\s*=?\s*(?P<q>["']?)(?P<cmd>.*?)(?P=q)$""")

# aerospace: only lines under [mode.*.binding] are bindings. The "key = value"
# lines under [gaps] or [[on-window-detected]] have the same shape, so tracking
# the table header is the only way to tell them apart.
AEROSPACE_MODE = re.compile(r"^\[mode\.(?P<mode>[\w-]+)\.binding\]")
AEROSPACE_BIND = re.compile(r"^(?P<key>[a-z0-9]+(?:-[a-z0-9]+)*)\s*=\s*(?P<val>.+)$", re.IGNORECASE)
QUOTED = re.compile(r"'([^']*)'|\"([^\"]*)\"")
WORKSPACE = re.compile(r"^workspace (\S+)$")
MOVE_NODE = re.compile(r"^move-node-to-workspace (\S+)$")
# markdown table row: | Jump to Claude | `⌃⌥J` | ... |
MD_ROW = re.compile(r"^\|(?P<cells>.+)\|$")
# "⌃⌥J" -> modifier run + base key
GLYPH_RUN = re.compile(r"^(?P<mods>[⌘⇧⌃⌥]+)(?P<base>.+)$")

PREFIX = "^a"
# read via fzf --ansi; visually separates alias rows from shortcuts
CYAN, DIM, RESET = "\033[36m", "\033[2m", "\033[0m"
GLYPHS = {"cmd": "⌘", "shift": "⇧", "ctrl": "⌃", "alt": "⌥", "opt": "⌥"}
SKIP_DESC = ("note:",)


def clean(text):
    return ARROW.sub("", text.strip()).strip(" -–—")


def pretty_key(key, sep="+"):
    """'cmd+shift+k' -> '⌘+⇧+K'; sep exists because aerospace separates keys with '-'."""
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
    """'⌃⌥J' -> '⌃+⌥+J'; the rest of the panel expects keys separated by '+'."""
    m = GLYPH_RUN.match(key)
    if not m:
        return key
    base = m.group("base")
    return "+".join(list(m.group("mods")) + [base.upper() if len(base) == 1 else base.title()])


def split_comment(text):
    """Splits a TOML line into value and trailing comment; a # inside quotes is not a comment."""
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
    """For matching: lowercase, no punctuation."""
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
                # "Note: ..." is a warning, not a description
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
            # a second map sending the same key, a keyboard layout variant; skip it
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
    """Bindings from the [mode.*.binding] tables; those outside the main mode get a prefix."""
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
        # multi-line array: join until the closing bracket
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
        # which key enters service mode is read from the config, not hardcoded.
        # The prefix is written without '+': it narrows the key column by 6
        # characters and matches the "⌃⌥J" spelling in the Raycast README.
        if cmds == ["mode service"]:
            service_prefix = key.replace("+", "")
        parsed.append({
            # every service-mode binding ends with 'mode main'; repeated noise
            "cmd": " · ".join(c for c in cmds if c != "mode main") or cmds[0],
            "key": f"{service_prefix} {key}" if mode != "main" and service_prefix else key,
            "note": note,
        })

    # move-node-to-workspace lines carry no comment; reuse the workspace binding note
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
        # aerospace comments carry parentheses of their own; use a dash as the separator
        desc = f"{row['cmd']} — {note}" if note else row["cmd"]
        rows.append({"kitty": row["key"], "tmux": "", "desc": desc, "section": "aerospace"})
    return rows


def parse_raycast():
    """The hotkey table in scripts/README.md - see the module docstring."""
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
        # the header and --- separator rows fall out on the key column
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
    """config.fish aliases + fish/functions/*.fish (custom commands)."""
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

            # keys like '"' and '%' are quoted; shlex splits them correctly
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
    """Merges kitty+tmux pairs that do the same job onto one row.

    The key is the byte kitty sends to tmux (\x01G -> "G"); the ⌘ twin in the
    -N note is only used for validation/fallback.
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


# arrow/named keys sort after letters and digits
NAMED_KEY_ORDER = ("Left", "Right", "Up", "Down", "Equal", "Minus")


def sort_key(row):
    """By key order: base key first, then modifier count.

    So ⌘+A and ⌘+⇧+A end up side by side, the plainer one (fewer modifiers) first.
    Rows with no kitty twin, tmux-only ones, sink to the bottom.
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


# fzf's pointer + border allowance: the row has to fit that much narrower space.
FZF_CHROME = 6


def term_width(default=80):
    """The panel output goes to a pipe, so the width is read from stderr's tty."""
    for stream in (sys.stderr, sys.stdout):
        try:
            return os.get_terminal_size(stream.fileno()).columns
        except (OSError, ValueError):
            continue
    try:
        return int(os.environ["COLUMNS"])
    except (KeyError, ValueError):
        return default


def main():
    rows = merge(parse_kitty(), parse_tmux()) + parse_aerospace() + parse_raycast() + parse_alias()
    if not rows:
        sys.exit("no shortcuts found")

    kw = max((len(r["kitty"]) for r in rows), default=0)
    tw = max((len(r["tmux"]) for r in rows), default=0)
    # Long alias commands ran to 185 characters and cut off the description in the
    # popup; keep the key columns whole and trim only from the tail.
    budget = term_width() - FZF_CHROME - kw - 2
    for r in sorted(rows, key=sort_key):
        sec = f"  · {r['section']}" if r["section"] else ""
        # keep alignment free of ANSI codes: pad first, then colorize
        name = f"{r['kitty']:<{kw}}"
        rest = f"{r['tmux']:<{tw}}  {r['desc']}{sec}"
        if budget > tw + 4 and len(rest) > budget:
            rest = rest[: budget - 1] + "…"
        if r["section"] == "alias":
            print(f"{CYAN}{name}{RESET}  {DIM}{rest}{RESET}")
        else:
            print(f"{name}  {rest}")


if __name__ == "__main__":
    main()
