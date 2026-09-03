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

9. Point git at the versioned hooks. `core.hooksPath` is local config, so a
   fresh clone has no hooks until this runs — and the pre-commit hook is what
   keeps `.claude/settings.json.example` from silently going stale or carrying
   `autoMode.environment` into this public repo.

```sh
git config core.hooksPath .config/git/hooks
```

10. Link the lazygit config. On macOS lazygit reads
   `~/Library/Application Support/lazygit`, not `~/.config`, so stow does not
   cover it.

```sh
ln -sf ~/workspace/dotfiles/.config/lazygit/config.yml \
  "$HOME/Library/Application Support/lazygit/config.yml"
```

11. Link the lazydocker config, same reason as lazygit.

```sh
ln -sf ~/workspace/dotfiles/.config/lazydocker/config.yml \
  "$HOME/Library/Application Support/lazydocker/config.yml"
```

12. Build the screen OCR helper `jira-to-branch` reads the Jira key with — the
   title itself comes from the API through jira-cli (step 18). It wraps the Vision
   framework, so nothing is installed beyond what macOS ships.

```sh
~/.local/share/screen-ocr/build.sh
```

13. Build the Claude Code menu bar indicator and load it at login. It shows the
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

14. Run the local model server `ai-oneshot` prefers. It listens on 11435, not
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

15. Move Scoot's hotkeys out of the `⌘` namespace. Scoot ships with `⇧⌘J/K/L`,
   and all three are taken in `kitty.conf` — `⇧⌘J` is the `prefix + j` jump to a
   waiting Claude session. A global hotkey wins over kitty, so the defaults would
   silently break three tmux bindings. `⌃⇧` is the only free modifier block.
   Carbon modifier `4608` is `control + shift`; key codes are J/K/L.

```sh
osascript -e 'quit app "Scoot"'
defaults write com.mjrusso.Scoot KeyboardShortcuts_useElementBasedNavigation \
  -string '{"carbonKeyCode":38,"carbonModifiers":4608}'
defaults write com.mjrusso.Scoot KeyboardShortcuts_useGridBasedNavigation \
  -string '{"carbonKeyCode":40,"carbonModifiers":4608}'
defaults write com.mjrusso.Scoot KeyboardShortcuts_useFreestyleNavigation \
  -string '{"carbonKeyCode":37,"carbonModifiers":4608}'
open -a Scoot
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Scoot.app", hidden:false}'
```

   The last line is what starts Scoot at login. Scoot ships no launch-at-login
   preference of its own — no `SMAppService` registration, no helper bundle — so
   without a login item it only runs when opened by hand.

   Scoot then needs Accessibility in System Settings → Privacy & Security.
   Element mode (`⌃⇧J`) reads real buttons through the accessibility API; grid
   mode (`⌃⇧K`) works without it.

16. Build the Picture-in-Picture defocus service and load it at login. cmd+tab is
   macOS's own app switcher and raises whichever window the app marks AXMain; Zen
   marks the PiP window AXMain the moment it is born, so cmd+tab lands on the
   floating video instead of the page behind it. AeroSpace cannot drive the fix —
   it never enumerates the PiP window, so its `on-focus-changed` callback goes
   silent exactly when PiP holds AXMain. Hence a service that watches the browser
   process directly. Zen turns out not to emit `AXWindowCreated` for the PiP
   either, so a one-second in-process poll backs the observer up; an AX round trip
   inside the process costs about a millisecond.

```sh
~/.local/share/zen-pip-defocus/build.sh
ln -sf ~/workspace/dotfiles/.local/share/zen-pip-defocus/com.ersanisik.zen-pip-defocus.plist \
  "$HOME/Library/LaunchAgents/com.ersanisik.zen-pip-defocus.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.ersanisik.zen-pip-defocus.plist"
```

   It then needs Accessibility in System Settings → Privacy & Security. The binary
   waits for the grant instead of exiting, so `KeepAlive` cannot spin it into a
   crash loop. Re-running `build.sh` changes the binary and macOS drops the grant
   with it — remove the entry and add it back rather than toggling it off and on,
   which leaves the stale one in place. `ZEN_PIP_DEBUG=1` on a manual run traces
   what the observer sees.

17. Install the Graylog JSON selector in Zen. Firefox will not permanently install
   an unsigned extension, so this ships as a userscript instead: install
   Violentmonkey, then paste
   `.local/share/graylog-json-select/graylog-json-select.user.js` into Dashboard →
   `+` → New script. Violentmonkey's own Import expects a zip backup, so handing it
   the `.user.js` file silently installs nothing, and a Firefox extension cannot
   read `file://` either — pasting is the only path. Violentmonkey then keeps its
   own copy; this file is the source, so a logic change has to be pasted again.

   The `@match`/`@include` hosts in the tracked file are deliberately placeholders
   that match nothing. Real Graylog hosts are internal infrastructure names and this
   repo is public, so they belong only in the Violentmonkey copy — which is also the
   copy that actually runs, so nothing is lost. The cost is that re-pasting after a
   logic change means re-entering the hosts. A Graylog on a non-default port needs
   `@include` rather than `@match`: the match-pattern host cannot carry a port, while
   the `@include` glob applies to the whole URL.

```sh
pbcopy < ~/.local/share/graylog-json-select/graylog-json-select.user.js
```

   Every detected payload gets a `{}` button in the gutter at its left edge, and
   clicking one selects that payload alone — the way to grab a single row out of a
   screen full of them. The buttons live in the shadow root of a fixed overlay on
   `document.body`, both because React reclaims anything injected into its own tree
   and because the observer below cannot see into a shadow tree, which is what
   keeps the buttons from triggering the rescan that draws them.

   `ctrl+j` selects the next JSON payload on the page whole, so `cmd+c` copies it
   without hand-dragging over a wrapped log line; the key repeats through every
   payload and wraps. Plain `⌃` is the only free modifier block left: `⌥` is
   aerospace's, `⌘` is kitty's, `⌃⌥` is Raycast's, and Scoot holds `⌃⇧J/K/L`.
   Detected payloads are tinted through the CSS Custom Highlight API rather than
   wrapped in elements, because Graylog is React and reclaims any DOM the script
   would inject. Payloads Graylog stores escaped inside a string field
   (`{\"a\":1}`) are found too, but the selection copies what is on screen — still
   escaped.

18. Configure jira-cli, which `jira-to-branch` reads the issue title from. Create
   an API token at <https://id.atlassian.com/manage-profile/security/api-tokens>,
   put it in the shell as `JIRA_API_TOKEN` — `work-paths.fish` is the place, it is
   already untracked — then run `init`, which asks for the server URL, the login
   e-mail and a default project.

```sh
jira init --installation cloud --auth-type basic
```

   The config lands in `~/.config/.jira/.config.yml` and is deliberately not
   tracked: it carries the company Jira URL and the login e-mail, and this repo is
   public. The token deliberately has no `WORK_` prefix either — `load-work-env.sh`
   copies every `WORK_*` variable into tmux's global environment, where a token has
   no business being.

   Skipping this step breaks nothing. `jira-to-branch` falls back to its old
   behaviour, guessing the title as the longest line of the OCR output, and says so
   on stderr. That guess is the reason for the step: the API answers with the exact
   summary in one call, which leaves OCR doing only what it is reliable at, reading
   the short `GD-1140` token. `jira-to-branch -k GD-1140` skips the screen entirely.

19. Start the window border service. AeroSpace runs with every gap set to 0, so a
   focused window carries no marker of its own — borders draws one. The colours
   live in `.config/borders/bordersrc`, which stow puts in place and the service
   reads on launch. `brew bundle` installs the formula but never starts a service,
   hence the step.

```sh
brew services start borders
```

   Editing `bordersrc` and then running it applies the change to the instance that
   is already running, so a colour tweak needs no service restart.

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

# Claude Code session state

Four things share one directory, `~/.local/state/claude-menubar/sessions`, so the
contract between them is worth writing down: the `claude-tmux-notify` hook, the
`claude-menubar` app, `claude-next.sh` (prefix + j), and the Raycast script
commands in `.config/raycast/scripts`.

- **One file per Claude session**, single-line JSON, always replaced by writing a
  temp file and renaming it. The rename is what wakes the menu bar app's directory
  watcher — an in-place rewrite leaves the icon stale. Single line so the reader can
  parse it with bash alone, without spawning `jq` on a keypress.
- **One reader, `claude-state.sh`**, next to the app that defines the contract.
  `claude-next.sh` and both Raycast scripts source it. The tmux side used to carry
  its own copy to avoid sourcing a file on a keypress; measured, that costs nothing
  (2.2 ms for an empty bash, 2.0 ms with the source), so the copy is gone.
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
- Keyboard-driven pointer: [Scoot](https://github.com/mjrusso/scoot)
- macOS package manager: [Homebrew](https://brew.sh)
- npm package manager: [pnpm](https://pnpm.io/)
