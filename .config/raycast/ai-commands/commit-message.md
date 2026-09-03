# Commit Message

Input comes from the clipboard: `git diff --staged | pbcopy`

- Alias: `cm`
- Model: Gemini 3.5 Flash Lite
- Creativity: None
- Output: Copy to Clipboard

```prompt
Produce a single Conventional Commits message for the git diff below.

Rules:
- Return only the commit message; add no explanation, quotes or code block.
- Format: <type>(<scope>): <subject>
- type: feat|fix|refactor|perf|test|docs|chore|build|ci
- subject in English, starts lowercase, imperative, no trailing period, at most 72 characters.
- Add a scope only if the diff touches a single module.
- If the diff contains several unrelated changes, pick the dominant one.
- Add no body.

Diff:
{clipboard}
```
