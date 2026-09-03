# Raycast Script Commands

Raycast Settings → Extensions → Script Commands → **Add Directory** →
`~/.config/raycast/scripts`. Stow puts this directory in place and Raycast reads
the files where they are; unlike the AI Commands, these really are versioned.

| Command | Hotkey | What it does |
| --- | --- | --- |
| Jump to Claude | `⌃⌥J` | Raises kitty on the Claude session that wants attention |
| Claude Sessions | `⌃⌥K` | Lists every running session, most urgent first |
| Screen OCR | `⌃⌥O` | Select a screen region, copy the text to the clipboard (macOS Vision) |
| Sesh Session | `⌃⌥S` | Raise kitty and switch to the matching sesh session |
| Shortcut Panel | `⌃⌥/` | Raise kitty, open the shortcut panel in a tmux popup |

**The table above is also data:** `keys-panel.py` reads its Raycast rows from
here. Raycast script hotkeys live in Raycast's own encrypted state, and this
table is the only file-based record — change a hotkey on the Raycast side and
update this too, or the panel shows the wrong key.

The `⌃⌥` block was chosen deliberately: aerospace has filled `⌥` and kitty `⌘`,
while `⌃⌥` is entirely free — a collision-free namespace for Raycast scripts.

## Writing a script in this directory

- **`#!/bin/bash`**, not `#!/usr/bin/env bash`. Raycast starts scripts with a
  restricted PATH, `env` cannot find brew's bash 5 there and you fall back to
  macOS's 3.2. Target 3.2: no `mapfile`, no associative arrays.
- **Set PATH by hand.** For the same reason `tmux`, `git` and `jq` are invisible;
  every script starts with `PATH="/opt/homebrew/bin:/usr/bin:/bin:..."`.
- **The shared reader is not here.** The code that parses Claude session state is
  in `~/.local/share/claude-menubar/claude-state.sh` — next to the app that
  defines the contract, and `claude-next.sh` sources the same file.

## Claude session state

The commit message command was removed from here: `aimsg` (`⌘+b`) does the same
job without going through Raycast at all — three candidates, an fzf pick,
`ctrl-r` for claude, scope from the Jira key in the branch name. No command in
this directory depends on Raycast AI any more.

`screen-ocr.sh` calls the Vision wrapper that `jira-to-branch` uses; the
`huzef44/screenocr` extension is no longer needed. `sesh.sh` also delegates the
jump to `claude-jump` — the aerospace race is solved there, it should not be
solved twice.

`keys-panel.sh` opens no new kitty window: the panel is already a tmux popup, and
aerospace tiled the new window into whatever workspace you were on, which moved
the panel visually. Instead it opens over the attached client with
`display-popup -c` and delegates raising to `claude-jump`.

`claude-jump.sh` and `claude-sessions.sh` read the single-line JSON files under
`~/.local/state/claude-menubar/sessions` — the contract is written down in the
main README. They do not jump themselves, they delegate to
`~/.local/bin/claude-jump`: from outside tmux, `switch-client` needs an attached
client, and that script exists exactly for this.

There is one reader: `~/.local/share/claude-menubar/claude-state.sh`. The tmux
side used to carry its own copy, justified as "do not source a file on a
keypress"; measured, there is no difference (2.2 ms for an empty bash, 2.0 ms
with the source), and the copy is gone.

Like prefix + j, `claude-jump.sh` only visits `waiting`, `done-bg` and `done`
sessions, and cycles them in the same order: pressing repeatedly advances instead
of locking onto one pane. It does not visit `working` sessions — there is nothing
to answer there.
