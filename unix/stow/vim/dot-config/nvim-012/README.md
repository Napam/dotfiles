# nvim-012

Personal Neovim 0.12+ config. Built on `vim.pack`. No plugin manager.

## Profiles

Two: `essentials` (default), `full`. Set via env:

```sh
LOCAL_NVIM_PLUGIN_MODE=ALL nvim   # full
nvim                              # essentials
```

`essentials` boots bare machine. No node/cargo/go/python need. LSP, lang plugins, debug stack skipped.
`full` loads everything.

Files gate via `Config.only_essential_plugins()`. Top of file:

```lua
if Config.only_essential_plugins() then return end
```

## Lockfiles

Per-profile. Both committed:

```
nvim-pack-lock.full.json        51 plugins
nvim-pack-lock.essentials.json  26 plugins
nvim-pack-lock.json             runtime, gitignored
```

Init.lua shim:

- **Startup**: if `nvim-pack-lock.json` missing, copy from `nvim-pack-lock.<profile>.json`. Hydrates fresh machine.
- **`PackChanged`**: copy runtime back to profile lock. Fires per plugin update.
- **`VimLeavePre`**: same. Catches anything missed.

Result: `:Pack update-all` updates plugins → autocmd writes back → `git diff` shows lock change → commit.

WARN: switching profile mid-machine leaves stale runtime lock. `rm ~/.config/nvim-012/nvim-pack-lock.json` then restart to re-hydrate.

## Commands

```vim
:Pack            " open UI
:Pack check      " fetch remotes, show pending updates
:Pack update-all " update all (opens confirm tab; :w to apply)
:Pack! update-all" update all, no confirm, write lock immediately
```

UI keymaps: `U` update all, `u` update under cursor, `C` check, `X` clean, `D` delete, `L` log, `?` help.

WARN: `vim.pack.update()` opens confirm tab. Lock written on `:w`. Close without `:w` → no checkout, no lock update. Use `:Pack!` variant to skip.

## stylua

Need `unzip` on PATH. Mason fetches pre-built binary as zip, no fallback.

```sh
brew install unzip   # mac
apt install unzip    # debian
```

## :TSUpdate race

`nvim-treesitter` parser install async. Calling `:TSUpdate` immediately after `vim.pack.add` races plugin load.

Fix in `0001_nvim-treesitter.lua`: `vim.defer_fn(install_parsers, 100)`. 100ms enough for `vim.pack.add` to finish wiring runtimepath.

## Layout

```
init.lua              entry, profile detect, lock shim
plugin/               auto-loaded files, vim.pack.add per plugin
plugin/0000_priority/ load before others (mason, treesitter)
plugin/lang/          per-language plugins (gated)
lua/                  shared modules (lazyload, merge, etc.)
queries/              treesitter query overrides
after/                runtime overrides
```

## Bootstrap fresh machine

```sh
git clone <dotfiles>
cd dotfiles && stow -d unix/stow -t ~ vim
nvim                    # essentials hydrates from .essentials.json
# or
LOCAL_NVIM_PLUGIN_MODE=ALL nvim   # full hydrates from .full.json
```

First run installs all plugins at lockfile revs. Subsequent runs use cached.
