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
nvim-pack-lock.full.json        54 plugins
nvim-pack-lock.essentials.json  26 plugins
nvim-pack-lock.json             runtime, gitignored
```

WARN: the lockfile is the profile's real plugin set. At the first
`vim.pack.add()` call, `vim.pack` installs every plugin in the lockfile, even
ones whose `plugin/` file was gated. A full-only entry left in the essentials
lock gets installed on a bare machine. `vim.pack.add()` gating only controls
what is loaded, not what the lockfile installs.

Init.lua shim (see `lua/packlock.lua`):

- **Startup**: build `nvim-pack-lock.json` from the active profile lock, then valid entries for already-installed plugins from the other profile lock, then from the previous runtime lock. Picks up profile switches without making `vim.pack` repair those extras on every startup.
- **`PackChanged`** (debounced 200ms): write the runtime entries that are in the committed profile lock or active this session to the current profile lock, then merge runtime revs into the other profile's lock. Cross-sync keeps shared plugins on identical revs across profiles.
- **`VimLeavePre`**: flush pending debounce + final sync. Catches anything missed.
- **Stale check**: 10s after `VimEnter`, warn about plugins in the profile lock that no `vim.pack.add()` registered. They still install on a fresh machine. `:Pack` tags installed ones `stale`; if no config adds them, `D` removes the directory and the lock entry. Uninstalled ones never show in `:Pack`; delete their entry from the committed lock by hand. Adds behind a callback that may never fire (parser install) register up front with `load = false` so they do not show up here.

Lock writes go through a temp file + rename, so a crash mid-write keeps the old lock.

WARN: `R` (restore) runs raw `git checkout`. `vim.pack` keeps the pre-restore revs in memory and has no API to reload them, so the shim pins the restored revs over its lock writes until `vim.pack` changes that plugin or nvim restarts.

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

UI keymaps: `U` update all, `u` update under cursor, `C` check remote, `R` restore all to lockfile revs, `X` clean non-active (skips plugins in the other profile's lock), `D` delete under cursor (extra confirm for other-profile plugins), `L` log, `<CR>` toggle details, `]]`/`[[` jump plugins, `?` help, `q`/`<Esc>` close.

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
