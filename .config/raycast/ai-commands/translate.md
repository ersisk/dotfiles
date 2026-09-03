# Translate TR ↔ EN

- Alias: `te`
- Model: Gemini 3.5 Flash Lite
- Creativity: None
- Output: Replace Selection

```prompt
Translate the text below.

Rules:
- If the text is Turkish, translate it to English; otherwise translate it to Turkish.
- Return only the translation; add no explanation, quotes or "Translation:" prefix.
- Leave technical terms, code fragments, product names and people's names as they are.
- Keep the tone of the source; casual stays casual, formal stays formal.
- If the direction is ambiguous (a single word valid in both languages), assume Turkish and translate to English.
- If the translation comes out identical to the source, translate the other way.

Text:
{selection}
```
