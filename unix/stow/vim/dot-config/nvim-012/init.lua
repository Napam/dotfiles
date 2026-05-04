---@diagnostic disable: duplicate-set-field
-- Inspired by https://github.com/fredrikaverpil/dotfiles

-- Before everything;
local nvim_start_time = vim.uv.hrtime()

-- Experimental Lua module loader.
vim.loader.enable()


-- States for this Neovim config.
_G.Config = {
  nvim_start_time = nvim_start_time,
  called = {},

  -- use_nvim_treesitter: gates plugin + auto-install autocmd + ensure_parser.
  -- use_treesitter_parser: gates lang plugins needing a parser (goplements,
  -- blink-go-import, go-impl). Implies use_nvim_treesitter (parser install
  -- routes through it) — disable both together.
  use_treesitter_parser = true,
  use_nvim_treesitter = true,

  -- Profile gate. Mirrors the nvim-0.11 config's `LOCAL_NVIM_PLUGIN_MODE`
  -- env var. Default = "essentials" (boots cleanly on a fresh machine with
  -- no node/cargo/go/python toolchains; only mason pre-built binaries).
  -- Set `LOCAL_NVIM_PLUGIN_MODE=ALL` to load everything.
  --
  -- Essentials excludes: LSP (blink requires cargo to build), per-language
  -- plugins, formatters/linters, fidget. Treesitter stays in essentials —
  -- mason ships tree-sitter-cli as a pre-built binary, so it works on a
  -- bare box.
  profile = (os.getenv("LOCAL_NVIM_PLUGIN_MODE") == "ALL") and "full" or "essentials",
}
function _G.Config.add(spec)
  require("merge")(_G.Config, spec)
end

--- True when running in the minimal "essentials" profile. Non-essential
--- plugin files should early-return at the top when this returns true.
---@return boolean
function _G.Config.only_essential_plugins()
  return Config.profile == "essentials"
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")
require("autocommands")

-- Experimental: ui2 message/cmdline redesign (:h ui2)
-- Avoids "Press ENTER" prompts, highlights cmdline, pager as buffer.
-- Wrapped in pcall: vim._core.ui2 is a private module and may move/disappear
-- across Neovim versions without warning.
local ok, ui2 = pcall(require, "vim._core.ui2")
if ok then
  pcall(ui2.enable)
end
