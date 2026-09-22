# opencode config notes

## Model variants

Variants are named options for one model, usually reasoning effort or token budgets.
Names come from the model's catalog metadata, so availability differs per model. An
unknown variant fails model resolution.

Pick a variant in the TUI with `/variants` (`variant.list`, listed only when the
current model has variants); `variant.cycle` (`ctrl+t`) cycles them.

### Per-agent

Join the variant to the model reference with `#`. Markdown frontmatter has no separate
`variant` key. JSON config also accepts an expanded
`{ "providerID": ..., "model": ..., "variant": ... }` object.

```yaml
---
model: <provider>/<model>#<variant>
---
```

### Model-wide

Set the default under `providers` → model → `settings`. A per-agent variant overrides
it.

```jsonc
"providers": {
  "<provider>": {
    "models": {
      "<model>": { "settings": { "reasoningEffort": "<effort>" } }
    }
  }
}
```

Define new variants, or replace catalog ones, in the model's `variants` array.

### Notes

- The root `model` field keeps only the provider and model, not a variant. Select
  variants on agents, commands, sessions, or one-off runs
  (`opencode run --model <provider>/<model>#<variant> ...`).
- Other providers use the same shape. OpenAI-compatible models take
  `settings.reasoningEffort`. Anthropic takes
  `settings.thinking: { "type": "enabled", "budgetTokens": N }`.
