# nvim-012

Personal Neovim 0.12+ config built on `vim.pack` (no plugin manager).
Inspired by
[fredrikaverpil/dotfiles](https://github.com/fredrikaverpil/dotfiles).

```sh
NVIM_APPNAME=nvim-012 nvim
```

## Layout

```
init.lua              _G.Config, options, keymaps
lua/                  libraries (lazyload, options, ...)
plugin/               auto-sourced alphabetically
  *.lua               core plugin configs
  lang/<ft>.lua       per-filetype: settings, extra plugins, autocmds
nvim-pack-lock.json   commit to VCS
```

## Startup phases

1. `init.lua`.
2. `plugin/**/*.lua` sourced **alphabetically, recursively** (`lang/` visits
   at its alpha position). Most files only enqueue work via `lazyload`.
3. `VimEnter` — `lazyload` drains: async first, then sync.
4. `FileType` / `BufRead` etc. fire as buffers open.

## `lazyload`

Defers expensive setup to VimEnter so startup stays fast.

```lua
require("lazyload").on_vim_enter(function()
  vim.pack.add({ { src = "https://github.com/foo/bar" } })
  require("bar").setup({ ... })
end)
```

- `on_vim_enter(fn, opts?)` — async by default; `{ sync = true }` runs after
  the async batch.
- `on_override(fn)` — runs after the entire VimEnter drain. For `.nvim.lua`
  exrc overrides that need to patch post-setup state.
- `call_once(fn)` — fire-once guard.

## Cross-plugin sharing via `_G.Config`

**Escape hatch for load-order coupling.** Top-level assignments in
`plugin/*.lua` execute at sourcing time, so they're available to every other
file's `on_vim_enter` callback regardless of alphabetical order.

```lua
-- plugin/producer.lua  (top level — runs at sourcing)
Config.foo = Config.foo or {}
function Config.foo.helper(x) ... end

require("lazyload").on_vim_enter(function() ... end)
```

```lua
-- plugin/lang/consumer.lua
require("lazyload").on_vim_enter(function()
  Config.foo.helper("bar")   -- always available
end)
```

**Rule:** if file A's lazyload block needs something file B owns, B publishes
it via `Config.*` at top level. Never rely on alphabetical luck between two
`on_vim_enter` callbacks.

## Idempotent helpers

`Config.ts.ensure_parser(lang)` (in `plugin/nvim_treesitter.lua`):

- Fast path: returns true if parser is already loadable.
- Slow path: lazily ensures `nvim-treesitter` is on rtp via `vim.pack.add`,
  installs synchronously (**blocks UI for up to 30 s** on first install),
  codesigns `.so` on macOS.
- Safe to call from any phase, any number of times.

A FileType autocmd (`treesitter-start` group) calls the same helper on demand
for any opened buffer — universal safety net for languages that don't opt in.
It is registered at `plugin/` sourcing time (Neovim startup step 11, see
`:h startup`) so it runs before LSP's FileType handlers, which are registered
at VimEnter.

## Build hooks

`PackChanged` autocmds for post-install steps. Register **before** the
matching `vim.pack.add` so they fire on first bootstrap:

```lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then vim.cmd("TSUpdate") end
  end,
})
vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter" } })
```

## Per-project overrides

Drop a `.nvim.lua` in `$cwd` or above. Runs at exrc (Neovim startup step 7c,
see `:h startup`), *before* `plugin/` is sourced. Use `lazyload.on_override`
to patch state that only exists post-setup:

```lua
require("lazyload").on_override(function()
  vim.lsp.config.gopls.settings = { gopls = { ... } }
end)
```

## Plugin management

- Install: `vim.pack.add` (typically inside `on_vim_enter`).
- Update: `:lua vim.pack.update()`, `:w` to apply.
- Lockfile: `nvim-pack-lock.json`.

## Adding a language

1. LSP → `plugin/lsp.lua`
2. Mason tools → `plugin/mason.lua`
3. Formatters → `plugin/conform.lua`
4. Linters → `plugin/lint.lua`
5. `plugin/lang/<ft>.lua` — filetype, `vim.opt_local` via FileType autocmd,
   `Config.ts.ensure_parser("<lang>")` if needed, then `vim.pack.add` +
   `setup()`.
6. Optional: `after/lsp/<server>.lua` to override base config.
