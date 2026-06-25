# opencode config notes

## Configuring model reasoning effort

`opencode-go/deepseek-v4-pro` exposes named **effort variants**, each mapping to a
`reasoningEffort` value:

| variant | reasoningEffort |
|---------|-----------------|
| `low`   | low             |
| `medium`| medium          |
| `high`  | high            |
| `max`   | max             |

(Verify a model's variants with `opencode models <provider> --verbose`.)

### Per-agent (frontmatter)

Set `variant:` in an agent's `agents/*.md` frontmatter. Applies only when the agent
uses its configured model.

```yaml
---
model: opencode-go/deepseek-v4-pro
variant: low   # less thinking; deep currently runs at medium
---
```

### Model-wide (all agents using that model)

Set it in `opencode.jsonc` under `provider` → model → `options`. A per-agent
`variant` overrides this.

```jsonc
"provider": {
  "opencode-go": {
    "models": {
      "deepseek-v4-pro": { "options": { "reasoningEffort": "low" } }
    }
  }
}
```

### Notes

- `variant` only works if the model actually declares a variant by that name —
  variants are model-defined, not free-form. Unknown values are silently ignored.
- Other reasoning shapes for other providers: OpenAI uses `options.reasoningEffort`
  (`minimal`/`low`/`medium`/`high`/`xhigh`); Anthropic uses
  `options.thinking: { type: "enabled", budgetTokens: N }`.
