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
  _priority/ NOTE: a literal `_` prefix sorts LAST on macOS (case-insensitive
              fs collation), so use a numeric prefix that sorts first.
  0000_priority/      sourced first (numeric prefix sorts before letters)
    00_*.lua          run at sourcing time, NOT inside lazyload
  *.lua               core plugin configs
  lang/<ft>.lua       per-filetype: settings, extra plugins, autocmds
nvim-pack-lock.json   commit to VCS
```

## Startup phases

1. `init.lua`.
2. `plugin/**/*.lua` sourced **alphabetically, recursively**.
   - `0000_priority/` sorts before all other plugin files because digits
     collate before letters in Neovim's runtime file scanner. (A bare `_`
     prefix would NOT work: macOS case-insensitive collation places leading
     underscore AFTER alphanumerics, opposite of pure ASCII byte order.)
     This directory contains setup that *must* run at sourcing time so later
     files can depend on it (mason PATH, nvim-treesitter rtp + custom
     parsers, the `treesitter-start` FileType autocmd,
     `Config.ts.ensure_parser`).
   - Other files mostly enqueue work via `lazyload`.
3. `VimEnter` — `lazyload` drains: async first, then sync.
4. `FileType` / `BufRead` etc. fire as buffers open.

## `0000_priority/` load order

Numeric prefix controls intra-directory order:

- `00_mason.lua` — `vim.pack.add(mason)`, `mason.setup({ PATH = "prepend" })`,
  then **synchronously installs `tree-sitter-cli`** (the `critical_sync`
  list) before returning, so mason-bin tools are on `vim.env.PATH` for every
  file sourced after this. Other tools install in the background.
- `10_nvim-treesitter.lua` — `vim.pack.add(nvim-treesitter)`, inject custom
  parsers, register `treesitter-start` FileType autocmd, expose
  `Config.ts.ensure_parser`. Depends on mason for the `tree-sitter` CLI used
  during parser compilation.

**First-install UI block.** On a clean install the synchronous step in
`00_mason.lua` blocks the UI for **up to 60 seconds per critical tool**
(typically ~5–15 s for `tree-sitter-cli`). This is intentional and a one-
time cost: subsequent runs short-circuit at `pkg:is_installed()`. Without
this block, `Config.ts.ensure_parser` would silently fail because
nvim-treesitter's compile step (`tree-sitter build`) would not find the CLI
on PATH and would return an error string that the async Task swallows
without propagating, masking the real problem.

Add new priority files with a numeric prefix that places them in the right
slot relative to mason and nvim-treesitter. Add a tool to `critical_sync`
in `00_mason.lua` only if a later sourcing-time consumer cannot tolerate
its absence (most tools belong in the background `ensure_installed` list).

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

## Treesitter parser auto-install

A FileType autocmd (`treesitter-start` group, in
`plugin/0000_priority/10_nvim-treesitter.lua`) auto-starts treesitter
highlighting for every opened buffer. If the parser isn't installed yet, it
installs synchronously via nvim-treesitter (**blocks UI for up to 30 s** on
first install) and codesigns the `.so` on macOS, then starts highlighting.

Registered at `plugin/` sourcing time (Neovim startup step 11, see
`:h startup`) so it runs before LSP's FileType handlers, which are registered
at VimEnter — preventing race conditions with plugins that use treesitter
queries on `LspAttach`.

Most per-language plugin files (`plugin/lang/<ft>.lua`) do NOT need to
pre-install parsers; the FileType autocmd is the universal mechanism. The
exception is plugins that query the parser at `require()` time (e.g.
`go-impl` calls `vim.treesitter.query.parse("go", ...)` at module load).
For those, call `Config.ts.ensure_parser` immediately before `require` —
see below.

## `Config.ts.ensure_parser(lang)`

Public helper in `plugin/0000_priority/10_nvim-treesitter.lua` (defined at
sourcing time, so available to every later `plugin/*.lua` file — both at
sourcing time and inside `on_vim_enter` callbacks).

- Fast path: returns true if parser is already loadable.
- Slow path: pre-flights `tree-sitter` CLI on PATH, installs synchronously
  via nvim-treesitter (**blocks UI for up to 30 s** on first install),
  codesigns `.so` on macOS, then performs three independent verifications:
  (1) the `.so` file exists on disk, (2) `vim.treesitter.language.add` loads
  it, (3) `vim.treesitter.query.parse` succeeds (catches missing queries —
  the actual API consumers like go-impl call). Returns `false` with a
  specific `vim.notify` warning at the first failed step.

The strict verification matters because nvim-treesitter's async install
Task completes "successfully" even when the underlying `tree-sitter build`
step errored (the error is logged, not propagated). Without the on-disk +
query.parse checks, `ensure_parser` would falsely return `true` and
consumers would crash later in unhelpful places.

**Calling rules.** Safe to call from anywhere after
`plugin/0000_priority/10_nvim-treesitter.lua` has sourced: top-level code in any
later `plugin/*.lua` file, any `on_vim_enter` callback (sync or async), or
any autocmd. The previous race (calling from an async `on_vim_enter` in a
file sourced before nvim-treesitter) is gone now that nvim-treesitter is
fully initialized at sourcing time in `0000_priority/`.

```lua
-- plugin/lang/foo.lua
require("lazyload").on_vim_enter(function()
  if Config.use_treesitter_parser and Config.ts.ensure_parser("foo") then
    vim.pack.add({ { src = "..." } })
    require("plugin-that-needs-foo-parser").setup({})
  end
end)
```

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
2. Mason tools → `plugin/0000_priority/00_mason.lua`
3. Formatters → `plugin/conform.lua`
4. Linters → `plugin/lint.lua`
5. `plugin/lang/<ft>.lua` — filetype, `vim.opt_local` via FileType autocmd,
   then `vim.pack.add` + `setup()` for any treesitter-dependent plugins.
   The treesitter parser is auto-installed on first buffer open by the
   `treesitter-start` FileType autocmd; no per-language opt-in needed.
6. Optional: `after/lsp/<server>.lua` to override base config.
