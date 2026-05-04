# AGENTS.md

## Comment style

Be brief. Comments cost reading time. Default to none.

### Keep

- **Footguns.** Prefix `WARN:`. Anything where the obvious code is wrong, where order matters, where an API lies (returns error vs throws), where a race exists.
- **HACK:** workarounds for upstream bugs. Link the issue if short.
- **PERF:** non-obvious perf choices (why slow API avoided).
- **Non-default config values** with rationale (one line: why not the default).
- **Forward declarations / closure capture** quirks — Lua-specific gotchas.
- **Cross-file ordering constraints** ("must run BEFORE X").

### Remove

- Decorative banners (`-- State`, `-- Keymaps`, `-- Normal --`, ASCII boxes).
- Restated code (`-- Close the window` above `function close()`).
- Section dividers between obvious blocks.
- Trailing per-line comments on uniform lists (`"taplo", -- pre-built binary`).
- Multi-paragraph essays. Collapse to 1–4 lines.
- "See README X" cross-refs unless the README has info not derivable from context.
- Attribution ("Inspired by …") unless legally required.
- Commented-out code without a `TODO:` or removal date.

### Format

- One-line where possible. Wrap at ~90 cols.
- `WARN:` / `HACK:` / `PERF:` / `TODO:` prefixes — greppable.
- Docstrings (`---@param`) stay; they're machine-readable, not prose.
- No emojis.

### Test

If the comment restates what the next 3 lines obviously do — delete it.
If removing it would let someone introduce a bug — keep it, mark `WARN:`.
