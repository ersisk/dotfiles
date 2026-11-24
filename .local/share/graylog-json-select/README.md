# Graylog JSON selector

Installation is in the main README under [Manual steps](../../../README.md#graylog-json-selector).

Every detected payload gets a `{}` button in the gutter at its left edge, and
clicking one selects that payload alone — the way to grab a single row out of a
screen full of them. The buttons live in the shadow root of a fixed overlay on
`document.body`, both because React reclaims anything injected into its own tree
and because the observer below cannot see into a shadow tree, which is what
keeps the buttons from triggering the rescan that draws them.

`ctrl+j` selects the next JSON payload on the page whole, so `cmd+c` copies it
without hand-dragging over a wrapped log line; the key repeats through every
payload and wraps. Plain `⌃` is the only free modifier block left: bare `⌥` is
AltGr on Turkish-Q, `⌘⌥⌃` is aerospace's (Caps Lock via Karabiner), `⌘` is kitty's,
`⌃⌥` is Raycast's, and Scoot holds `⌃⇧J/K/L`.
Detected payloads are tinted through the CSS Custom Highlight API rather than
wrapped in elements, because Graylog is React and reclaims any DOM the script
would inject. Payloads Graylog stores escaped inside a string field
(`{\"a\":1}`) are found too, but the selection copies what is on screen — still
escaped.
