---@diagnostic disable: duplicate-set-field
-- Inspired by https://github.com/fredrikaverpil/dotfiles

local nvim_start_time = vim.uv.hrtime()

vim.loader.enable()

-- use_treesitter_parser implies use_nvim_treesitter (parser install routes through it).
-- profile=essentials boots on a bare machine (no node/cargo/go/python); LSP/lang plugins skipped.
_G.Config = {
  nvim_start_time = nvim_start_time,
  called = {},
  use_treesitter_parser = true,
  use_nvim_treesitter = true,
  profile = (os.getenv("LOCAL_NVIM_PLUGIN_MODE") == "ALL") and "full" or "essentials",
}
function _G.Config.add(spec)
  require("merge")(_G.Config, spec)
end

--- True when running in the minimal "essentials" profile.
---@return boolean
function _G.Config.only_essential_plugins()
  return Config.profile == "essentials"
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Per-profile vim.pack lockfile shim. See lua/packlock.lua.
-- WARN: must run BEFORE any vim.pack.add (plugin/* files load after init.lua).
require("packlock").setup()

require("options")
require("keymaps")
require("autocommands")

-- vim._core.ui2 is private; pcall in case it moves/disappears across versions.
local ok, ui2 = pcall(require, "vim._core.ui2")
if ok then
  pcall(ui2.enable)
end
