# Erşan Işık's Dotfiles

This is the home of all my dotfiles. These are files that add custom configurations to my computer and applications, primarily the terminal.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

## How to install

My dotfiles are managed by [GNU Stow](https://www.gnu.org/software/stow/).

1. Install [homebrew](https://brew.sh/)
2. Clone this repository
3. Run the bootstrap script. It installs the Brewfile, stows the repo into `~`
   and does every other step that can be scripted — each one is described, with
   the reason for it, under [What bootstrap.sh does](#what-bootstrapsh-does).
   Every step checks before it acts, so it is safe to re-run after a pull.

```sh
./bootstrap.sh          # set up whatever is missing
./bootstrap.sh doctor   # only report; exits non-zero when something is off
```

4. Fill in `~/.config/fish/conf.d/work-paths.fish`. Bootstrap copies it from
   `work-paths.fish.example` with placeholder paths. Work session paths in
   `sesh.toml` read from it; without the file the work sessions are skipped and
   everything else keeps working.

5. Do the [manual steps](#manual-steps) — the ones no script can reach.

On Linux there is no bootstrap; `stow . -t ~` is the whole install.

## What bootstrap.sh does

All three Swift tools are rebuilt only when their source is newer than the
binary.

### Brewfile

`brew bundle install --no-upgrade`, with Homebrew's `bin` put first on `PATH`.
The Brewfile's `npm` entries are globals of brew's node, but fnm's node comes
first in an interactive shell, and `brew bundle check` then looks for them in
fnm's prefix and reports them missing. Run a manual check the same way:

```sh
PATH="/opt/homebrew/bin:$PATH" brew bundle check --no-upgrade --verbose
```

### Claude Code settings

Copies the settings from the example when `~/.claude/settings.json` is missing.
The live file is deliberately **not** tracked: Claude Code writes
`autoMode.environment` into it — organisation name, private repo names, CI
secret names, deploy targets — and this repo is public. The example is a
generated snapshot, so it goes stale on its own; regenerate it after changing
settings, and read the diff before committing rather than trusting the filter to
know what is sensitive.

```sh
jq 'del(.autoMode.environment)' ~/.claude/settings.json \
  > ~/workspace/dotfiles/.claude/settings.json.example
```

### Git hooks

Points `core.hooksPath` at `.config/git/hooks`. It is local config, so a fresh
clone has no hooks until this runs — and the pre-commit hook is what keeps
`.claude/settings.json.example` from silently going stale or carrying
`autoMode.environment` into this public repo.

### lazygit and lazydocker

Links both configs into `~/Library/Application Support`. On macOS they read from
there, not from `~/.config`, so stow does not cover them.

### Screen OCR helper

Builds the helper `jira-to-branch` reads the Jira key with — the title itself
comes from the API through jira-cli (see [jira-cli](#jira-cli)). It wraps the
Vision framework, so nothing is installed beyond what macOS ships.

### Coding-agent menu bar indicator

Builds it and loads its LaunchAgent. It shows the state of every running Claude
Code and opencode session (needs input / working / background task / finished)
and jumps to the session's tmux pane when clicked, which is what
`agent-tmux-notify` feeds through `~/.local/state/agent-menubar/sessions`.

### Local model server

Loads the ollama LaunchAgent and pulls `qwen3`, the model `ai-oneshot` prefers.
It listens on 11435, not ollama's default 11434, because the `rubberduck-ollama`
container publishes that port and answers with an empty model list —
`ai-oneshot` probes 11435 first and falls back to 11434, then to `claude -p`.

### Scoot hotkeys

Moves Scoot's hotkeys out of the `⌘` namespace. Scoot ships with `⇧⌘J/K/L`, and
all three are taken in `kitty.conf` — `⇧⌘J` is the `prefix + j` jump to a
waiting Claude session. A global hotkey wins over kitty, so the defaults would
silently break three tmux bindings. `⌃⇧` is the only free modifier block.
Carbon modifier `4608` is `control + shift`; key codes are J/K/L.

Bootstrap also adds Scoot as a login item. Scoot ships no launch-at-login
preference of its own — no `SMAppService` registration, no helper bundle — so
without a login item it only runs when opened by hand.

### Picture-in-Picture defocus service

Builds it and loads its LaunchAgent. cmd+tab is macOS's own app switcher and
raises whichever window the app marks AXMain; Zen marks the PiP window AXMain
the moment it is born, so cmd+tab lands on the floating video instead of the
page behind it. AeroSpace cannot drive the fix — it never enumerates the PiP
window, so its `on-focus-changed` callback goes silent exactly when PiP holds
AXMain. Hence a service that watches the browser process directly. Zen turns out
not to emit `AXWindowCreated` for the PiP either, so a one-second in-process poll
backs the observer up; an AX round trip inside the process costs about a
millisecond.

The binary waits for its Accessibility grant instead of exiting, so `KeepAlive`
cannot spin it into a crash loop. `ZEN_PIP_DEBUG=1` on a manual run traces what
the observer sees.

### Window borders

Starts the `borders` service. AeroSpace runs with every gap set to 0, so a
focused window carries no marker of its own — borders draws one. The colours
live in `.config/borders/bordersrc`, which stow puts in place and the service
reads on launch. `brew bundle` installs the formula but never starts a service.

Editing `bordersrc` and then running it applies the change to the instance that
is already running, so a colour tweak needs no service restart.

## Manual steps

`./bootstrap.sh doctor` reports the opencode key and the jira-cli config when
they are missing; the rest it cannot see.

### Raycast

Point Raycast at the script commands: Settings → Extensions → Script Commands →
Add Directory → `~/.config/raycast/scripts`. Stow already put the directory
there; see its README for the commands and their hotkeys.

Recreate the Raycast AI commands by hand from `.config/raycast/ai-commands/` —
Raycast keeps them in an encrypted database, so stow cannot install them.

### Accessibility

Grant Accessibility in System Settings → Privacy & Security to:

- **Scoot.** Element mode (`⌃⇧J`) reads real buttons through the accessibility
  API; grid mode (`⌃⇧K`) works without it.
- **zen-pip-defocus.** Rebuilding it changes the binary and macOS drops the grant
  with it — remove the entry and add it back rather than toggling it off and on,
  which leaves the stale one in place.

### Graylog JSON selector

Install the Graylog JSON selector in Zen. Firefox will not permanently install
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

What the script does once installed is described in
[its own README](.local/share/graylog-json-select/README.md).

### jira-cli

Configure jira-cli, which `jira-to-branch` reads the issue title from. Create an
API token at <https://id.atlassian.com/manage-profile/security/api-tokens>, put
it in the shell as `JIRA_API_TOKEN` — `work-paths.fish` is the place, it is
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

### opencode gateway key

Write opencode's LLM gateway key. `.config/opencode/opencode.json` is versioned
but the key is not: the config pulls it in with `{file:...}`, which opencode
resolves at load — a plain env var would not survive a pane started by
`new-window` rather than a login shell.

```sh
printf '%s' 'sk-...' > ~/.config/opencode/llmroute.key
chmod 600 ~/.config/opencode/llmroute.key
```

Skills need no step: opencode scans `~/.claude/skills` and `~/.agents/skills` on
its own, and reads `~/.claude/CLAUDE.md` as global instructions, so both agents
share one set. `opencode debug skill` lists what it found.

## Design notes

Component internals live next to their code:

- [Shortcut panel](.config/tmux/README.md) — `prefix + ?`, the searchable list
  of every binding.
- [Coding-agent session state](.local/share/agent-menubar/README.md) — the
  contract between `agent-tmux-notify`, the menu bar app, `prefix + j` and the
  Raycast scripts.

## Software

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
