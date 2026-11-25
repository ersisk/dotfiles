// agent-tmux-notify (opencode) — bridges opencode's event bus to the notifier.
//
// agent-tmux-notify is written against Claude Code's hook contract: a JSON
// payload on stdin, out of which come the tmux window-state glyph, the styled
// status-line message and the menubar state file. opencode has no hook
// mechanism, so this plugin subscribes to its event bus and synthesises the
// same payloads — one notifier, two agents.
//
// Event mapping (opencode → Claude Code hook event):
//   session.created / first session seen  → SessionStart
//   chat.message                          → UserPromptSubmit
//   tool.execute.before                   → PreToolUse
//   tool.execute.after  (bash only)       → PostToolUse
//   permission.asked / question.asked     → Notification
//   permission.replied / question.replied → UserPromptSubmit (back to working)
//   session.error                         → Notification
//   session.idle                          → Stop
//   session.deleted                       → SessionEnd
//   subagent session created / idle       → SubagentStart / SubagentStop
//
// Subagent sessions are tracked and excluded from the session-level mapping: a
// finished subagent must not mark the pane done while the root session is
// still working. Their tool calls and asks are reported under the root session
// id, so they keep the root's row on "working" instead of opening rows of their own.

import { spawn } from "node:child_process";
import { closeSync, openSync, writeSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";

const NOTIFY =
  process.env.AGENT_TMUX_NOTIFY ||
  join(homedir(), ".local", "bin", "agent-tmux-notify");
// Kilo is an opencode fork that loads this same file from its own plugins dir.
const AGENT = basename(process.execPath).startsWith("kilo") ? "kilo" : "opencode";

// opencode tool ids are lower case; agent-tmux-notify branches on Claude Code's
// names for the two it treats specially. Everything else is passed through as is
// and only ever lands in the "working" detail line.
const TOOL_NAMES = { bash: "Bash", task: "Task" };

const ASK_GRACE_MS = 1500;

// Serialised: PreToolUse stashes a start timestamp that PostToolUse reads back,
// so payloads must reach the script in the order they were produced.
let chain = Promise.resolve();

function send(payload) {
  reportRex(payload.hook_event_name);
  chain = chain.then(() => run(payload)).catch(() => {});
  return chain;
}

// Rex reads an agent's state from OSC 7501 (rex-reviews keys "done" off it).
// Claude Code reports it natively; opencode and kilo do not, so the plugin does.
const IN_REX = Boolean(process.env.REX_SESSION);
const REX_STATE = {
  UserPromptSubmit: "working",
  PreToolUse: "working",
  Notification: "blocked",
  Stop: "done",
};
let rexState = "";

function reportRex(event) {
  const state = REX_STATE[event];
  if (!IN_REX || !state || state === rexState) return;
  rexState = state;
  try {
    const fd = openSync("/dev/tty", "w");
    writeSync(fd, `\x1b]7501;state=${state}:app=${AGENT}\x1b\\`);
    closeSync(fd);
  } catch {}
}

function run(payload) {
  return new Promise((resolve) => {
    const child = spawn(NOTIFY, { stdio: ["pipe", "ignore", "ignore"] });
    let settled = false;
    const done = () => {
      if (settled) return;
      settled = true;
      resolve();
    };
    // A missing or non-executable notifier surfaces as an async "error" event,
    // never a throw, so silence has to be wired up on both the child and its pipe.
    child.on("error", done);
    child.on("close", done);
    child.stdin.on("error", done);
    try {
      child.stdin.end(JSON.stringify(payload));
    } catch {
      done();
    }
  });
}

export const AgentTmuxNotifyPlugin = async ({ directory, worktree }) => {
  const rootDir = directory || worktree || process.cwd();

  // Subagent session → its parent, so lifecycle events can be dropped and the
  // rest attributed to the root session.
  const childSessions = new Map();
  // Subagents between their start and their idle; the root's row counts them.
  const runningChildren = new Set();
  // sessionID → directory, for sessions opened in another worktree.
  const sessionDirs = new Map();
  // sessionID → id of the assistant message currently streaming, so a text part
  // can be attributed without keeping every message id ever seen.
  const assistantMessage = new Map();
  // sessionID → that assistant message's text; the "done" detail line.
  const lastText = new Map();
  // permission request id → timer of its not-yet-sent Notification.
  const pendingAsks = new Map();

  let started = false;

  const cwdFor = (sessionID) => sessionDirs.get(sessionID) || rootDir;

  const rootOf = (sessionID) => {
    let id = sessionID;
    while (childSessions.has(id)) id = childSessions.get(id);
    return id;
  };

  const payload = (event, sessionID, extra = {}) => ({
    hook_event_name: event,
    session_id: sessionID || "",
    cwd: cwdFor(sessionID),
    agent: AGENT,
    ...extra,
  });

  // Claude Code fires SessionStart before anything else; opencode has no
  // equivalent, so the first root session we see stands in for it. Without this
  // a fresh pane carries no menubar row until the first prompt.
  const childStarted = (id) => {
    if (runningChildren.has(id)) return;
    runningChildren.add(id);
    send(payload("SubagentStart", rootOf(id), { agent_id: id }));
  };

  const ensureStarted = (sessionID) => {
    if (started || !sessionID || childSessions.has(sessionID)) return;
    started = true;
    send(payload("SessionStart", sessionID));
  };

  return {
    "chat.message": async ({ sessionID }) => {
      if (!sessionID) return;
      // A finished subagent the task tool prompts again is running again.
      if (childSessions.has(sessionID)) return childStarted(sessionID);
      ensureStarted(sessionID);
      lastText.delete(sessionID);
      await send(payload("UserPromptSubmit", sessionID));
    },

    "tool.execute.before": async ({ tool, sessionID }, output) => {
      const args = output?.args ?? {};
      await send(
        payload("PreToolUse", rootOf(sessionID), {
          tool_name: TOOL_NAMES[tool] || tool,
          tool_input: {
            command: args.command ?? "",
            description: args.description ?? "",
            run_in_background: false,
          },
        }),
      );
    },

    "tool.execute.after": async ({ tool, sessionID, args }) => {
      // Only bash is timed on the far side; sending the rest would be a process
      // spawn per tool call for a branch that exits immediately.
      if (tool !== "bash") return;
      await send(
        payload("PostToolUse", rootOf(sessionID), {
          tool_name: "Bash",
          tool_input: { command: args?.command ?? "" },
        }),
      );
    },

    event: async ({ event }) => {
      const type = event?.type;
      const props = event?.properties ?? {};

      switch (type) {
        case "session.created":
        case "session.updated": {
          const info = props.info;
          if (!info?.id) return;
          if (info.parentID) {
            if (childSessions.has(info.id)) return;
            childSessions.set(info.id, info.parentID);
            childStarted(info.id);
            return;
          }
          if (info.directory) sessionDirs.set(info.id, info.directory);
          ensureStarted(info.id);
          return;
        }

        case "session.deleted": {
          const id = props.info?.id;
          if (!id || childSessions.has(id)) return;
          await send(payload("SessionEnd", id));
          sessionDirs.delete(id);
          assistantMessage.delete(id);
          lastText.delete(id);
          return;
        }

        case "message.updated": {
          const info = props.info;
          if (info?.role === "assistant" && info.sessionID) {
            assistantMessage.set(info.sessionID, info.id);
          }
          return;
        }

        case "message.part.updated": {
          // Attributed rather than "last text part wins": a user part arrives on
          // the same stream and would otherwise be echoed back as the answer.
          const part = props.part;
          if (part?.type !== "text" || !part.sessionID) return;
          if (assistantMessage.get(part.sessionID) !== part.messageID) return;
          const text = (part.text || "").trim();
          if (text) lastText.set(part.sessionID, text);
          return;
        }

        case "session.idle": {
          const id = props.sessionID;
          if (!id) return;
          if (childSessions.has(id)) {
            if (!runningChildren.delete(id)) return;
            await send(payload("SubagentStop", rootOf(id), { agent_id: id }));
            return;
          }
          await send(
            payload("Stop", id, { last_message: lastText.get(id) || "" }),
          );
          return;
        }

        // The two ways opencode blocks on the user. The notifier keys the detail
        // line off the word "permission", so the prefix is load-bearing: without
        // it the approval request loses to the last assistant message.
        case "permission.asked": {
          const id = rootOf(props.sessionID);
          if (!id) return;
          const patterns = Array.isArray(props.patterns)
            ? props.patterns.join(", ")
            : "";
          const what = [props.permission, patterns].filter(Boolean).join(" ");
          const notify = () =>
            send(
              payload("Notification", id, {
                message: `permission: ${what || "requested"}`,
              }),
            );
          // The TUI's auto-approve mode answers every ask right after it is
          // published, so notifying at once would flag each tool call as input.
          if (!props.id) return notify();
          pendingAsks.set(
            props.id,
            setTimeout(() => {
              pendingAsks.delete(props.id);
              notify();
            }, ASK_GRACE_MS),
          );
          return;
        }

        case "question.asked": {
          const id = rootOf(props.sessionID);
          if (!id) return;
          const first = props.questions?.[0];
          await send(
            payload("Notification", id, {
              message: first?.question || first?.header || "question",
            }),
          );
          return;
        }

        // The ask happens inside the tool, after tool.execute.before, so nothing
        // else flips the pane back while the approved call runs. A rejection that
        // ends the turn still lands on session.idle afterwards.
        case "permission.replied":
        case "question.replied":
        case "question.rejected": {
          const id = rootOf(props.sessionID);
          if (!id) return;
          const timer = pendingAsks.get(props.requestID);
          if (timer) {
            clearTimeout(timer);
            pendingAsks.delete(props.requestID);
            return;
          }
          await send(payload("UserPromptSubmit", id));
          return;
        }

        case "session.error": {
          const id = props.sessionID;
          if (!id || childSessions.has(id)) return;
          // Errors also come from the throwaway models opencode runs on the side
          // (session titles), and the pane says "needs input" either way — naming
          // the failure is what tells the two apart.
          const err = props.error;
          await send(
            payload("Notification", id, {
              message: err?.data?.message || err?.name || "session error",
            }),
          );
          return;
        }

        default:
          return;
      }
    },
  };
};
