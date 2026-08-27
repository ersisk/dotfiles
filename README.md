# Erşan Işık's Dotfiles

This is the home of all my dotfiles. These are files that add custom configurations to my computer and applications, primarily the terminal.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

## How to install

My dotfiles are managed by [GNU Stow](https://www.gnu.org/software/stow/).

1. Install [homebrew](https://brew.sh/)
2. Install [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`)
3. Clone this repository
4. Run stow command

```sh
stow . -t ~
```

5. Copy `.config/fish/conf.d/work-paths.fish.example` to
   `~/.config/fish/conf.d/work-paths.fish` and fill in your own paths.
   Work session paths in `sesh.toml` read from it; without the file the
   work sessions are skipped and everything else keeps working.

6. Point Raycast at the script commands: Settings → Extensions → Script
   Commands → Add Directory → `~/.config/raycast/scripts`. Stow already put the
   directory there; see its README for the commands and their hotkeys.

7. Recreate the Raycast AI commands by hand from
   `.config/raycast/ai-commands/` — Raycast keeps them in an encrypted
   database, so stow cannot install them.

8. Copy the Claude Code settings from the example. The live file is
   deliberately **not** tracked: Claude Code writes `autoMode.environment` into
   it — organisation name, private repo names, CI secret names, deploy targets —
   and this repo is public. The example is a generated snapshot, so it goes
   stale on its own; regenerate it after changing settings, and read the diff
   before committing rather than trusting the filter to know what is sensitive.

```sh
cp .claude/settings.json.example ~/.claude/settings.json

# refresh the example after changing settings
jq 'del(.autoMode.environment)' ~/.claude/settings.json \
  > ~/workspace/dotfiles/.claude/settings.json.example
```

9. Link the lazygit config. On macOS lazygit reads
   `~/Library/Application Support/lazygit`, not `~/.config`, so stow does not
   cover it.

```sh
ln -sf ~/workspace/dotfiles/.config/lazygit/config.yml \
  "$HOME/Library/Application Support/lazygit/config.yml"
```

10. Link the lazydocker config, same reason as lazygit.

```sh
ln -sf ~/workspace/dotfiles/.config/lazydocker/config.yml \
  "$HOME/Library/Application Support/lazydocker/config.yml"
```

11. Build the screen OCR helper `jira-to-branch` reads Jira titles with. It wraps
   the Vision framework, so nothing is installed beyond what macOS ships.

```sh
~/.local/share/screen-ocr/build.sh
```

12. Build the Claude Code menu bar indicator and load it at login. It shows the
   state of every running Claude Code session (needs input / working / background
   task / finished) and jumps to the session's tmux pane when clicked, which is
   what the `claude-tmux-notify` hook feeds through
   `~/.local/state/claude-menubar/sessions`.

```sh
~/.local/share/claude-menubar/build.sh
ln -sf ~/workspace/dotfiles/.local/share/claude-menubar/com.ersanisik.claude-menubar.plist \
  "$HOME/Library/LaunchAgents/com.ersanisik.claude-menubar.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.ersanisik.claude-menubar.plist"
```

13. Run the local model server `ai-oneshot` prefers. It listens on 11435, not
   ollama's default 11434, because the `rubberduck-ollama` container publishes
   that port and answers with an empty model list — `ai-oneshot` probes 11435
   first and falls back to 11434, then to `claude -p`.

```sh
ln -sf ~/workspace/dotfiles/.local/share/ollama/com.ersanisik.ollama.plist \
  "$HOME/Library/LaunchAgents/com.ersanisik.ollama.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.ersanisik.ollama.plist"
ollama pull qwen3
```

# Claude Code session state

Four things share one directory, `~/.local/state/claude-menubar/sessions`, so the
contract between them is worth writing down: the `claude-tmux-notify` hook, the
`claude-menubar` app, `claude-next.sh` (prefix + j), and the Raycast script
commands in `.config/raycast/scripts`.

- **One file per Claude session**, single-line JSON, always replaced by writing a
  temp file and renaming it. The rename is what wakes the menu bar app's directory
  watcher — an in-place rewrite leaves the icon stale. Single line so
  `claude-next.sh` can parse it with bash alone, without spawning `jq` on a keypress.
- **`claude-tmux-notify` is the primary writer**, one write per hook event. The
  menu bar app only fills gaps: a pane running `claude` with no file at all gets one
  written from what tmux still knows, marked `"recovered": true`. Without that, a
  session already waiting for input when its file went missing could never announce
  itself again — the next hook event is exactly what is not coming.
- **`@claude_state` (per tmux window) means "unacknowledged work"**, and it is the
  second half of the contract: the hook sets the state glyph, and the app *unsets* it
  when it clears an entry you have looked at — also stripping the glyph from the window
  *name*, since a window with `automatic-rename off` never re-renders it from the
  option. Without that durable acknowledgement, recovery would resurrect every
  finished session from the glyph on the next tick.
  The glyph list therefore lives in two places — `claude-tmux-notify`
  (`set_window_state`) and `ClaudeMenubar.swift` (`phaseByGlyph`).
- **An entry is dropped** when its pane is gone, when no `claude` is left on its
  recorded tty (a crash or ctrl-C fires no `SessionEnd`), or when it is finished and
  its pane is on screen. Every drop is logged with its reason to
  `/tmp/claude-menubar.err.log`.
- **The three surfaces have separate jobs.** The menu bar is the ambient one: it is
  on screen even when kitty is not focused, and it tracks every session including the
  finished and idle ones. `prefix + j` is the keyboard one, but it only exists once you
  are already in tmux. Raycast (`⌃⌥J`) is the one that works from Slack or a browser;
  it reuses `claude-jump` rather than reimplementing the switch. The tmux status bar
  used to carry a fourth copy of the same signal; it was removed rather than kept in
  sync.
- **launchd gives the app no UTF-8 locale**, and tmux then mangles its own output:
  a tab in a format string becomes `_` and emoji session names become `__ Main`.
  Hence `LANG` in the LaunchAgent plist. Related rule: an unparsable `list-panes`
  answer must be treated as "cannot tell", never as "every pane is gone".

# Software

- Terminal: [Kitty](https://sw.kovidgoyal.net/kitty/)
- Font: [Maple Mono Nerd Font](https://font.subf.dev/en/)
- Colors: [Kanagawa](https://github.com/rebelot/kanagawa.nvim)
- Shell: [Fish](https://fishshell.com/)
- Multiplexer: [Tmux](https://github.com/tmux/tmux/wiki)
- Editor: [Neovim](https://neovim.io)
- Editor Config: [AstroNvim](https://astronvim.github.io/)
- Git: [Lazygit](https://github.com/jesseduffield/lazygit)
- macOS package manager: [Homebrew](https://brew.sh)
- npm package manager: [pnpm](https://pnpm.io/)
