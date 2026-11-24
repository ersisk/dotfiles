# Shortcut panel

`prefix + ?` (and `⌃⌥/` from outside tmux) opens `.config/tmux/keys-panel.sh`,
a searchable list of every binding on this machine. It parses the config files
themselves rather than a hand-written cheatsheet, so a new binding shows up
without touching the panel:

- **kitty** — the comment line above each `map`.
- **tmux** — the `-N` note on each `bind`. Pairs that do the same job are merged
  onto one row, keyed by the byte kitty sends (`\x01G` → `G`), not by the note.
- **aerospace** — `[mode.*.binding]` tables and the end-of-line comment naming
  the app. Bindings outside the main mode are prefixed with whatever key enters
  their mode, read from the config rather than hardcoded. `[gaps]` and
  `[[on-window-detected]]` carry `key = value` lines of the same shape, so the
  table header is what tells bindings apart from settings.
- **Raycast** — the hotkey table in `.config/raycast/scripts/README.md`. This is
  the one mirror: Raycast keeps script hotkeys in its own encrypted state, so
  that table is the only file-based record. Change a hotkey in Raycast and the
  table goes stale, and so does the panel.
- **fish** — aliases from `config.fish` and the function names under
  `fish/functions`, listed dimmed after the shortcuts.
