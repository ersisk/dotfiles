# Coding-agent session state

Four things share one directory, `~/.local/state/agent-menubar/sessions`, so the
contract between them is worth writing down: the `agent-tmux-notify` hook, the
`agent-menubar` app, `agent-next.sh` (prefix + j), and the Raycast script
commands in `.config/raycast/scripts`.

- **One file per agent session**, single-line JSON, always replaced by writing a
  temp file and renaming it. The rename is what wakes the menu bar app's directory
  watcher — an in-place rewrite leaves the icon stale. Single line so the reader can
  parse it with bash alone, without spawning `jq` on a keypress. **The pane id is the
  only durable coordinate in it:** tmux renumbers window indices when a window is
  closed or moved, so the recorded `session:window` is a hint as old as the last hook
  event and `agent-jump` re-derives the pair from the pane before switching. On a stale
  index `select-window` fails and `select-pane` merely rearranges an off-screen window
  — a jump that looks like it did nothing.
- **One reader, `agent-state.sh`**, next to the app that defines the contract.
  `agent-next.sh` and the Raycast jump script source it. The tmux side used to carry
  its own copy to avoid sourcing a file on a keypress; measured, that costs nothing
  (2.2 ms for an empty bash, 2.0 ms with the source), so the copy is gone.
- **`agent-tmux-notify` is the primary writer**, one write per hook event. Claude
  Code calls it directly as a hook; opencode has no hook mechanism, so
  `.config/opencode/plugins/agent-tmux-notify.js` subscribes to its event bus and
  synthesises the same payloads. The payload's `agent` field is how the two are told
  apart — absent means Claude Code. The menu bar app only fills gaps: a pane running
  an agent with no file at all gets one written from what tmux still knows, marked
  `"recovered": true`. Without that, a session already waiting for input when its
  file went missing could never announce itself again — the next hook event is
  exactly what is not coming.
- **`@agent_state` (per tmux window) means "unacknowledged work"**, and it is the
  second half of the contract: the hook sets the state glyph, and the app *unsets* it
  when it clears an entry you have looked at — also stripping the glyph from the window
  *name*, since a window with `automatic-rename off` never re-renders it from the
  option. Without that durable acknowledgement, recovery would resurrect every
  finished session from the glyph on the next tick.
  The glyph list therefore lives in two places — `agent-tmux-notify`
  (`set_window_state`) and `AgentMenubar.swift` (`phaseByGlyph`). The set of
  process names that count as an agent is a third such place:
  `AgentMenubar.swift` (`agentComms`), which is what keeps an opencode pane from
  being pruned as dead. `ps` calls it `opencode` even though tmux calls the pane
  command `opencode.exe`.
- **An entry is dropped** when its pane is gone, when no agent process is left on
  its recorded tty (a crash or ctrl-C fires no `SessionEnd`), or when it is finished and
  its pane is on screen in the frontmost app. Every drop is logged with its reason to
  `/tmp/agent-menubar.err.log`.
- **The three surfaces have separate jobs.** The menu bar is the ambient one: it is
  on screen even when kitty is not focused, and it tracks every session including the
  finished and idle ones. `prefix + j` is the keyboard one, but it only exists once you
  are already in tmux. Raycast (`⌃⌥J`) is the one that works from Slack or a browser;
  it reuses `agent-jump` rather than reimplementing the switch. `⌃⇧A` opens the menu
  bar's own menu from anywhere and numbers its rows, so a digit picks a session — the
  only surface that reaches a *working* or *idle* one from outside tmux, since both
  jump keys deliberately visit nothing but the sessions that want an answer. The tmux
  status bar used to carry a fourth copy of the same signal; it was removed rather
  than kept in sync.
- **launchd gives the app no UTF-8 locale**, and tmux then mangles its own output:
  a tab in a format string becomes `_` and emoji session names become `__ Main`.
  Hence `LANG` in the LaunchAgent plist. Related rule: an unparsable `list-panes`
  answer must be treated as "cannot tell", never as "every pane is gone".
