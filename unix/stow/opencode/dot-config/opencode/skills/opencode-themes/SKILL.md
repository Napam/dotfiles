---
name: opencode-themes
description: >
  Use when editing "opencode theme" files ("theme.json", "theme colors", "kanagawa",
  "backgroundPanel", "custom theme") in ~/.config/opencode/themes/: covers file shape,
  color resolution, fallbacks, and which theme keys map to which UI surfaces.
---

# opencode themes

Theme files live in `~/.config/opencode/themes/`. In this repo:
`unix/stow/opencode/dot-config/opencode/themes/`. The file name is the theme
name in the picker. Reference example: `kanagawa-transparent.json`. Facts below
verified against opencode 1.18.18 source (`packages/tui/src/theme/index.ts`,
`ui/dialog.tsx`, `ui/dialog-select.tsx`, `component/command-palette.tsx`).
`~/.config/opencode/` is stow-managed and points here, so edits are live.

## File shape

```json
{
  "$schema": "https://opencode.ai/theme.json",
  "defs": { "crystalBlue": "#7E9CD8" },
  "theme": { "primary": "crystalBlue", "background": "none" }
}
```

`defs` is the named palette. Each `theme` value is one of:

- `"#RRGGBB"` hex. Always valid.
- A def name (string ref).
- `{ "dark": "...", "light": "..." }`. Picks `.dark` or `.light` by the
  terminal's default background luminance (>0.5 = light). No opencode setting.
- ANSI int (`0`-`255`).

## Resolution

- String refs resolve through `defs` first, then `theme` keys.
- `"none"` and `"transparent"` resolve to RGBA(0,0,0,0): fully transparent.
  `background: "none"` shows the terminal background through.
- Missing ref throws (`Color reference X not found in defs or theme`). Circular
  refs throw.
- Hex strings never fail. A dark-only theme can collapse every variant to a
  plain hex and skip the `.dark`/`.light` split.

## Fallbacks

- `backgroundMenu` absent: uses `backgroundElement`.
- `selectedListItemText` absent: uses `background`. Skimping on this makes
  selected rows unreadable in pickers.
- `background` alpha 0 (transparent): selected-row text is black or white,
  chosen by luminance of `primary` (or row bg), not the normal fallback.
  Defining `selectedListItemText` overrides this.
- `thinkingOpacity` absent: 0.6.

## UI surfaces (the non-obvious part)

| Surface | Theme key |
| --- | --- |
| ctrl+p command palette / dialog modal box background | `backgroundPanel` (not `backgroundMenu`) |
| Filter input background (focused) | `backgroundPanel` |
| Selected row highlight in the picker | `primary`, or per-option `bg` |
| Selected row text | `selectedListItemText` |
| Picker category headers | `accent` |
| Dialog full-screen backdrop | hardcoded `RGBA(0,0,0,150)`, not themeable |

The modal backdrop is semi-transparent black at alpha 150, hardcoded in
dialog.tsx. Design around it, don't try to theme it.

Semantic keys beyond the table: `primary`, `secondary`, `accent`, `error`,
`warning`, `success`, `info`; `text`, `textMuted`; `border`, `borderActive`,
`borderSubtle`; plus `markdown*`, `syntax*`, `diff*` families. Full set in
`kanagawa-transparent.json`.

Builtin scopes map to `theme.error`: `variable.builtin`, `type.builtin`,
`function.builtin`, `module.builtin`, `constant.builtin`. Builtin identifiers
render in the error color.

## Selection priority

Built-in defaults < plugin themes < custom files in themes dir < generated
system theme. Custom file name is the theme name.

## Edit hygiene

- Every def should be referenced by `theme`. Raw hex equal to a def value:
  replace with the def name. One-off shades (diff backgrounds, line numbers)
  stay raw.
- Themes load at startup, no hot reload. After saving, the user must quit and
  restart opencode.
