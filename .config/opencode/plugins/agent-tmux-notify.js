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
//   session.error                         → Notification
//   session.idle                          → Stop
//   session.deleted                       → SessionEnd
//
// Subagent sessions are tracked and excluded from the session-level mapping: a
// finished subagent must not mark the pane done while the root session is
// still working. Their tool calls still keep the pane on "working".

import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const NOTIFY =
  process.env.AGENT_TMUX_NOTIFY ||
  join(homedir(), ".local", "bin", "agent-tmux-notify");
const AGENT = "opencode";

// opencode tool ids are lower case; agent-tmux-notify branches on Claude Code's
// names for the two it treats specially. Everything else is passed through as is
// and only ever lands in the "working" detail line.
const TOOL_NAMES = { bash: "Bash", task: "Task" };

// Serialised: PreToolUse stashes a start timestamp that PostToolUse reads back,
// so payloads must reach the script in the order they were produced.
let chain = Promise.resolve();

function send(payload) {
  chain = chain.then(() => run(payload)).catch(() => {});
  return chain;
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

  // Subagent sessions, so their lifecycle events can be dropped.
  const childSessions = new Set();
  // sessionID → directory, for sessions opened in another worktree.
  const sessionDirs = new Map();
  // sessionID → id of the assistant message currently streaming, so a text part
  // can be attributed without keeping every message id ever seen.
  const assistantMessage = new Map();
  // sessionID → that assistant message's text; the "done" detail line.
  const lastText = new Map();

  let started = false;

  const cwdFor = (sessionID) => sessionDirs.get(sessionID) || rootDir;

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
  const ensureStarted = (sessionID) => {
    if (started || !sessionID || childSessions.has(sessionID)) return;
    started = true;
    send(payload("SessionStart", sessionID));
  };

  return {
    "chat.message": async ({ sessionID }) => {
      if (!sessionID || childSessions.has(sessionID)) return;
      ensureStarted(sessionID);
      lastText.delete(sessionID);
      await send(payload("UserPromptSubmit", sessionID));
    },

    "tool.execute.before": async ({ tool, sessionID }, output) => {
      const args = output?.args ?? {};
      await send(
        payload("PreToolUse", sessionID, {
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
        payload("PostToolUse", sessionID, {
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
            childSessions.add(info.id);
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
          if (!id || childSessions.has(id)) return;
          await send(
            payload("Stop", id, { last_message: lastText.get(id) || "" }),
          );
          return;
        }

        // The two ways opencode blocks on the user. The notifier keys the detail
        // line off the word "permission", so the prefix is load-bearing: without
        // it the approval request loses to the last assistant message.
        case "permission.asked": {
          const id = props.sessionID;
          if (!id) return;
          const patterns = Array.isArray(props.patterns)
            ? props.patterns.join(", ")
            : "";
          const what = [props.permission, patterns].filter(Boolean).join(" ");
          await send(
            payload("Notification", id, {
              message: `permission: ${what || "requested"}`,
            }),
          );
          return;
        }

        case "question.asked": {
          const id = props.sessionID;
          if (!id) return;
          const first = props.questions?.[0];
          await send(
            payload("Notification", id, {
              message: first?.question || first?.header || "question",
            }),
          );
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
