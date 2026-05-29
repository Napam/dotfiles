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
nvim-pack-lock.full.json        52 plugins
nvim-pack-lock.essentials.json  25 plugins
nvim-pack-lock.json             runtime, gitignored
```

Init.lua shim (see `lua/packlock.lua`):

- **Startup**: copy `nvim-pack-lock.<profile>.json` → `nvim-pack-lock.json` unconditionally. Picks up profile switches; previous session's `VimLeavePre` already flushed runtime → committed, so no data lost.
- **`PackChanged`** (debounced 200ms): copy runtime → current profile lock, then merge shared-plugin revs into the other profile's lock. Cross-sync keeps shared plugins on identical revs across profiles.
- **`VimLeavePre`**: flush pending debounce + final sync. Catches anything missed.

Result: `:Pack update` updates plugins → autocmd writes back → `git diff` shows lock change → commit.

Profile switch: just relaunch with/without `LOCAL_NVIM_PLUGIN_MODE=ALL`. Startup re-hydrates from the new profile's committed lockfile.

## Commands

```vim
:Pack             " open UI
:Pack check       " fetch remotes, show pending updates
:Pack update      " update all (opens confirm tab; :w to apply)
:Pack update-all  " synonym for :Pack update
:Pack! update     " update all, no confirm, write lock immediately
:PackLockSyncTo <profile>  " manually sync overlapping plugins from other profile's lock
```

UI keymaps: `U` update all, `u` update under cursor, `C` check remote, `R` restore all to lockfile revs, `X` clean non-active, `D` delete under cursor, `L` log, `<CR>` toggle details, `]]`/`[[` jump plugins, `?` help, `q`/`<Esc>` close.

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
