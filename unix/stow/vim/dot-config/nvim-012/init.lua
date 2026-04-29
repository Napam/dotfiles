-- Inspired by https://github.com/fredrikaverpil/dotfiles

-- Before everything;
local nvim_start_time = vim.uv.hrtime()

-- Experimental Lua module loader.
vim.loader.enable()


-- States for this Neovim config.
_G.Config = {
  nvim_start_time = nvim_start_time,
  called = {},

  -- treesitter
  -- `use_nvim_treesitter` gates the nvim-treesitter plugin itself and the
  -- `Config.ts.ensure_parser` helper. `use_treesitter_parser` gates per-
  -- language plugins that depend on a parser being present (e.g. goplements,
  -- blink-go-import). The latter implies the former: if you disable
  -- `use_nvim_treesitter` you should also disable `use_treesitter_parser`,
  -- since parser installation currently goes through nvim-treesitter.
  use_treesitter_parser = true,
  use_nvim_treesitter = true,
}
function _G.Config.add(spec)
  require("merge")(_G.Config, spec)
end

---@param repo string
---@return string
_G.gh = function(repo)
  return "https://github.com/" .. repo
end

---@param repo string
---@param opts table | nil
---@return nil
_G.vimpackadd = function(repo, opts)
  local final_opts = vim.tbl_extend("force", { confirm = false }, opts or {})
  vim.pack.add({ gh(repo) }, final_opts)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")

-- Experimental: ui2 message/cmdline redesign (:h ui2)
-- Avoids "Press ENTER" prompts, highlights cmdline, pager as buffer.
require("vim._core.ui2").enable()
