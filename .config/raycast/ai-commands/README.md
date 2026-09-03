# Raycast AI Commands

Raycast keeps AI Commands encrypted inside `raycast-enc.sqlite`; there is no
export. This directory is therefore a **source-text archive**: the prompts here
are pasted into Raycast by hand, and nothing syncs back. Change a prompt on the
Raycast side and update the file here too, or the archive lies.

Setup: Raycast → `Create AI Command` → take the title from the file name, the
prompt from the ```prompt``` block, and set Model/Creativity/Output as the file says.

| Command | Alias | Input | Prompt here? |
| --- | --- | --- | --- |
| Explain Error | `ee` | `{selection}` | ✔ |
| Commit Message | `cm` | `{clipboard}` (`git diff --staged \| pbcopy`) | ✔ — but `aimsg` does it better |
| Translate TR ↔ EN | `te` | `{selection}` | ✔ |

`jira-to-branch` used to chain two AI commands from here (`parse-jira-title`,
`generate-branch`) and the `screenocr` extension through deeplinks. It no longer
does: macOS Vision handles the OCR, `claude -p` the translation, and nothing goes
through the clipboard. Those three Raycast commands can be deleted, nothing else
uses them.

## Model choice

The catalogue lives in `defaults read com.raycast.macos raycastAI_modelInfo`;
every model carries an `intelligence` and `speed` score and a `requires_better_ai`
flag. The choices below come from there, not from the names — a model badged
"Pro" is not necessarily smarter than a Flash.

**Gemini 3.7 Flash** is the only Pareto winner among the models that need no
add-on: intelligence 4, speed 5, vision + web search + reasoning effort. Raycast's
own default (GPT-5.6 Luna, intelligence 3 / speed 4) is below it on both axes.
Do not be fooled by the name `Gemini 3 Flash`, that one is intelligence 2.

Mechanical work (translation, commit message, jira parsing) goes to
**Gemini 3.5 Flash Lite**: intelligence 3, speed 5. Latency, not model
intelligence, is what decides those, especially in clipboard-polling chains like
`jira-to-branch`.

Models flagged `requires_better_ai` (Claude Opus 5, GPT-5.6 Sol, Gemini 3.1 Pro)
need the Advanced AI add-on. Not worth buying: Raycast is the short, fast surface
here, and the heavy thinking already happens in Claude Code in the terminal.
